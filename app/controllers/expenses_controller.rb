# frozen_string_literal: true

# What is left of the server-rendered expense: the two exports, which the
# plan keeps server-rendered on purpose. The list, the form and the bulk
# actions are the SPA's, and go through /api/v1.
class ExpensesController < ApplicationController
  def index
    authorize! :read, :expenses

    expenses = current_account.expenses.filter_result(filter_params)

    respond_to do |format|
      format.csv do
        # Named and typed like the pdf below it: without either, the download
        # arrives as an unnamed octet-stream.
        send_data expenses.to_csv, type: "text/csv", filename: "expenses.csv"
      end
      format.pdf do
        expense_pdf = ExpensePdf.new(current_account, expenses, filter_params)
        send_data expense_pdf.inline_pdf, filename: "#{expense_pdf.pdf_file}.pdf",
          type: "application/pdf", disposition: "inline"
      end
    end
  end

  private def filter_params
    params.permit(:year, :type, :quarter, :month, :query)
  end
end
