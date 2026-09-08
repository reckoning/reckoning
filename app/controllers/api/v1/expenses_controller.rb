# frozen_string_literal: true

module Api
  module V1
    class ExpensesController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.base"))
      end

      before_action :check_feature_enabled

      after_action -> { pagination_header(:expenses) }, only: [:index]

      def index
        authorize! :read, :expenses

        scope = current_account.expenses
          .filter_result(filter_params)
          .with_attached_receipt
          .order(date: :desc, created_at: :desc)

        @expenses = paginate(scope)
      end

      # The list prints what the filtered set adds up to, which paging cannot
      # answer: page two knows nothing about page one. Same filters, so the
      # numbers belong to the set the list is showing.
      def summary
        authorize! :read, :expenses

        scope = current_account.expenses.filter_result(filter_params)
        year = (filter_params[:year].presence || Time.zone.now.year).to_i

        @count = scope.count
        @value = deductible_sum(scope, year)
        @vat = normalized(scope).sum(&:vat_value)
        @years = filter_years
      end

      def show
        @expense = find_expense
        authorize! :read, @expense
      end

      def create
        @expense = current_account.expenses.new(expense_params)
        authorize! :create, @expense

        if @expense.save
          render :show, status: :created
        else
          render json: ValidationError.new("expense.create", @expense.errors), status: :bad_request
        end
      end

      def update
        @expense = find_expense
        authorize! :update, @expense

        return render :show if @expense.update(expense_params)

        render json: ValidationError.new("expense.update", @expense.errors), status: :bad_request
      end

      def destroy
        @expense = find_expense
        authorize! :destroy, @expense

        if @expense.destroy
          render json: {message: resource_message(:expense, :destroy, :success)}
        else
          render json: ValidationError.new("expense.destroy", @expense.errors), status: :bad_request
        end
      end

      # Applies the same attributes to many expenses — the bulk edit bar on the
      # expenses table. Reports how many actually changed rather than assuming
      # all of them did.
      def bulk_update
        authorize! :update, Expense

        expenses = current_account.expenses.where(id: bulk_ids)
        attributes = bulk_attributes

        if expenses.empty? || attributes.empty?
          return render json: ValidationError.new("expense.bulk_update"), status: :bad_request
        end

        updated = expenses.count { |expense| expense.update(attributes) }

        render json: {count: updated, message: I18n.t(:"expenses.bulk.updated", count: updated)}
      end

      def bulk_destroy
        authorize! :destroy, Expense

        expenses = current_account.expenses.where(id: bulk_ids)

        if expenses.empty?
          return render json: ValidationError.new("expense.bulk_destroy"), status: :bad_request
        end

        destroyed = expenses.count { |expense| expense.destroy }

        render json: {count: destroyed, message: I18n.t(:"expenses.bulk.destroyed", count: destroyed)}
      end

      # An expense on an interval stands for one entry per period it covers,
      # so the sums are taken over those rather than over the records. Health
      # and social insurance sit outside the total unless that is what you
      # asked to see — they are not business expenses, and the panel that
      # reports them counts them separately.
      private def normalized(scope, year = filter_params[:year].presence)
        return ::Expense.normalized(scope.to_a, year: year) if filter_params[:type] == "insurances"

        ::Expense.normalized(scope.without_insurances.to_a, year: year)
      end

      # An AfA expense deducts one year's write-off rather than its value, and
      # that share does not repeat per period — so it is counted once from the
      # records instead of from the normalized entries.
      private def deductible_sum(scope, year)
        write_offs = scope.filter_type(:afa).sum { |expense| expense.afa_value(year) }

        normalized(scope).sum { |expense|
          next 0 if expense.expense_type == "afa"

          expense.usable_value(year)
        } + write_offs
      end

      # The year dropdown offers a run of years, newest first, the way the
      # server-rendered filter did. It reads the first year off the expenses
      # themselves, where the helper behind the old screen read it off the
      # first *invoice* — an account with expenses and no invoices could not
      # reach the year its expenses were in.
      private def filter_years
        current = (Time.zone.now.month == 12) ? 1.year.from_now.year : Time.zone.now.year
        earliest = [
          current_account.expenses.minimum(:date)&.year,
          current_account.expenses.minimum(:started_at)&.year
        ].compact.min

        ((earliest || 1.year.ago.year)..current).to_a.reverse
      end

      # Expenses are behind an account feature flag, same as the web UI.
      private def check_feature_enabled
        return if current_account.feature_expenses?

        render json: {
          code: "feature.disabled",
          message: I18n.t("validation_error.expense.feature_disabled")
        }, status: :forbidden
      end

      private def find_expense
        current_account.expenses.find(params[:id])
      end

      private def filter_params
        params.permit(:year, :type, :quarter, :month, :query)
      end

      private def bulk_ids
        Array(params[:expenseIds] || params[:expense_ids]).reject(&:blank?)
      end

      private def bulk_attributes
        openapi_params(::V1::Schemas::Inputs::ExpenseBulkInput)
          .to_h
          .except("expenseIds", "expense_ids")
          .reject { |_, value| value.blank? }
      end

      private def expense_params
        @expense_params ||= openapi_params(::V1::Schemas::Inputs::ExpenseInput)
      end
    end
  end
end
