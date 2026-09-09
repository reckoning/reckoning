# frozen_string_literal: true

class ExpenseImportsController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav
  # The SPA's list hands its filters to the import in the url, so the
  # redirect at the end of it lands back on the same filtered list.
  before_action :store_list_filters, only: [:new]

  def new
    authorize! :create, ExpenseImport
    @expense_import = ExpenseImport.new
  end

  def preview
    authorize! :create, ExpenseImport
    @expense_import = ExpenseImport.new(preview_params.merge(account_id: current_account.id))
    @expenses = @expense_import.preview_expenses

    if @expenses.empty?
      flash.now[:error] = resource_message(:expense, :import, :failure)
      render :new, status: :unprocessable_entity
    else
      render :preview
    end
  end

  def create
    authorize! :create, ExpenseImport
    @expense_import = ExpenseImport.new(create_params.merge(account_id: current_account.id))
    if @expense_import.save
      redirect_to expenses_path(stored_params(:index, "expenses")), flash: {success: resource_message(:expense, :import, :success)}
    else
      @expenses = @expense_import.selected_expenses
      render :preview, status: :unprocessable_entity
    end
  end

  private def preview_params
    @preview_params ||= params.require(:expense_import).permit(
      :file, :expense_type, :vat_percent, :private_use_percent, :interval, :skip_credits
    )
  end

  private def create_params
    permitted = params.require(:expense_import)
    {rows: Array(permitted[:rows]&.values).map { |row| row.permit(:include, *ExpenseImport::ROW_ATTRIBUTES).to_h }}
  end

  # Under the expenses list's own key, which is where the redirect below
  # reads it back from.
  private def store_list_filters
    session[:expenses_index] = params.permit(:year, :type, :quarter, :month, :query).to_h.compact_blank
  end

  private def set_active_nav
    @active_nav = "expenses"
  end
end
