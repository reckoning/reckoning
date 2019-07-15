# frozen_string_literal: true

class ExpenseImportsController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def new
    authorize! :create, ExpenseImport
    @expense_import = ExpenseImport.new
  end

  def create
    authorize! :create, ExpenseImport
    @expense_import = ExpenseImport.new(import_params.merge(account_id: current_account.id))
    if @expense_import.save
      redirect_to expenses_path(stored_params(:index, 'expenses_controller')), flash: { success: resource_message(:expense, :import, :success) }
    else
      render :new
    end
  end

  private def import_params
    @import_params ||= params.require(:expense_import).permit(:file)
  end

  private def set_active_nav
    @active_nav = 'expenses'
  end
end
