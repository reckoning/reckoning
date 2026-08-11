# frozen_string_literal: true

module Api
  module V1
    # Two-step bank statement import: preview parses the upload into unsaved
    # expenses, create persists the rows the user kept.
    class ExpenseImportsController < ::Api::BaseController
      before_action :check_feature_enabled

      # Multipart, not JSON — this one takes a file.
      def preview
        authorize! :create, ExpenseImport

        @expense_import = ExpenseImport.new(preview_params.merge(account_id: current_account.id))
        @expenses = @expense_import.preview_expenses

        if @expenses.empty?
          render json: ValidationError.new("expense.import"), status: :unprocessable_entity
        else
          render :preview
        end
      end

      def create
        authorize! :create, ExpenseImport

        @expense_import = ExpenseImport.new(rows: create_rows, account_id: current_account.id)

        if @expense_import.save
          @expenses = @expense_import.selected_expenses
          render :create, status: :created
        else
          render json: ValidationError.new("expense.import", @expense_import.errors),
            status: :unprocessable_entity
        end
      end

      private def check_feature_enabled
        return if current_account.feature_expenses?

        render json: {
          code: "feature.disabled",
          message: I18n.t("validation_error.expense.feature_disabled")
        }, status: :forbidden
      end

      private def preview_params
        params.permit(:file, :expense_type, :vat_percent, :private_use_percent, :interval, :skip_credits)
      end

      # Rows come back as an array here rather than the nested hash the form
      # posts, so there is no `.values` dance.
      private def create_rows
        Array(params[:rows]).map do |row|
          row.permit(:include, *ExpenseImport::ROW_ATTRIBUTES).to_h
        end
      end
    end
  end
end
