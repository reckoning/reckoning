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
        # Seeded with decimals: an empty set would otherwise sum to an
        # integer zero and cross the wire as a number where the schema — and
        # every non-empty answer — has a string.
        @value = deductible_sum(scope, year)
        @vat = normalized(scope).sum(0.to_d, &:vat_value)
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

      # The receipt is a file: it is uploaded on its own rather than inside
      # the expense's json, which is why this one is multipart.
      def update_receipt
        @expense = find_expense
        authorize! :update, @expense

        # Checked before the attachment is touched. Attaching to a saved
        # record writes at once and pushes the previous receipt out, so a
        # rejected upload would take the receipt that was already there with
        # it — and that one cannot be put back, because replacing it has
        # already queued its file for deletion.
        return render json: ValidationError.new("expense.receipt"), status: :bad_request unless acceptable_receipt?

        @expense.receipt.attach(receipt_file)

        render :show
      end

      def destroy_receipt
        @expense = find_expense
        authorize! :update, @expense

        @expense.receipt.purge

        render :show
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
      private def normalized(scope)
        year = filter_params[:year].presence
        entries = if filter_params[:type] == "insurances"
          ::Expense.normalized(scope.to_a, year: year)
        else
          ::Expense.normalized(scope.without_insurances.to_a, year: year)
        end

        window = filter_window
        return entries if window.nil?

        entries.select { |entry| entry.date.present? && window.cover?(entry.date) }
      end

      # The sums have to belong to the set the list is showing, so the periods
      # of an expense on an interval are counted only where the filter looks:
      # a monthly expense filtered to March is one entry, not twelve.
      # `filter_quarter` and `filter_month` read the year the same way, from
      # the filter or from today.
      private def filter_window
        year = (filter_params[:year].presence || Time.zone.now.year).to_i
        month = filter_params[:month].presence.to_i
        quarter = filter_params[:quarter].presence.to_i

        windows = []
        windows << (Date.new(year, month, 1)..Date.new(year, month, -1)) if (1..12).cover?(month)
        windows << (Date.new(year, quarter * 3 - 2, 1)..Date.new(year, quarter * 3, -1)) if (1..4).cover?(quarter)
        windows << (Date.new(year, 1, 1)..Date.new(year, 12, 31)) if filter_params[:year].present?

        return nil if windows.empty?

        # Month and quarter are separate dropdowns and can both be set, and
        # `filter_result` chains them — so the window is where they overlap.
        # Where they do not, the range comes out backwards and covers
        # nothing, which is the same answer the list gives.
        windows.map(&:first).max..windows.map(&:last).min
      end

      # An AfA expense deducts one year's write-off rather than its value, and
      # that share does not repeat per period — so it is counted once from the
      # records instead of from the normalized entries.
      private def deductible_sum(scope, year)
        write_offs = scope.filter_type(:afa).sum(0.to_d) { |expense| expense.afa_value(year) }

        normalized(scope).sum(0.to_d) { |expense|
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
        years = [
          current_account.expenses.minimum(:date)&.year,
          current_account.expenses.minimum(:started_at)&.year,
          current_account.expenses.maximum(:date)&.year,
          current_account.expenses.maximum(:ended_at)&.year
        ].compact

        # Clamped both ways: an expense dated ahead of today would otherwise
        # leave the range empty and the dropdown with nothing in it, not even
        # the year being looked at.
        first = [years.min || 1.year.ago.year, current].min
        last = [years.max || current, current].max

        (first..last).to_a.reverse
      end

      # Expenses are behind an account feature flag, same as the web UI.
      private def check_feature_enabled
        return if current_account.feature_expenses?

        render json: {
          code: "feature.disabled",
          message: I18n.t("validation_error.expense.feature_disabled")
        }, status: :forbidden
      end

      private def receipt_file
        params[:receipt]
      end

      private def acceptable_receipt?
        receipt_file.present? &&
          receipt_file.respond_to?(:content_type) &&
          ::Expense::RECEIPT_CONTENT_TYPES.include?(receipt_file.content_type)
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
