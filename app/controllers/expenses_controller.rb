class ExpensesController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def index
    authorize! :read, :expenses
    expenses = current_account.expenses
                              .filter(filter_params)
    @expenses_sum = expenses.sum(:value)
    @expenses = expenses.order(sort_column + " " + sort_direction)
                        .page(params.fetch(:page, nil))
                        .per(20)
  end

  def new
    authorize! :create, Expense
    @expense = current_account.expenses.new
  end

  def create
    authorize! :create, Expense
    if expense.save
      redirect_to expenses_path, flash: { success: resource_message(:expense, :create, :success) }
    else
      flash.now[:alert] = resource_message(:expense, :create, :failure)
      render "new"
    end
  end

  def edit
    authorize! :create, expense
  end

  def update
    authorize! :update, expense
    if expense.update_attributes(expense_params)
      redirect_to expenses_path, flash: { success: resource_message(:expense, :update, :success) }
    else
      flash.now[:alert] = resource_message(:expense, :update, :failure)
      render "edit"
    end
  end

  def destroy
    authorize! :destroy, expense

    if expense.destroy
      flash[:success] = resource_message(:expense, :destroy, :success)
    else
      flash[:alert] = resource_message(:expense, :destroy, :failure)
    end

    respond_to do |format|
      format.js { render json: {}, status: :ok }
      format.html { redirect_to expenses_path }
    end
  end

  private def filter_params
    params.permit(:year)
  end
  helper_method :filter_params

  private def sort_column
    Expense.column_names.include?(params[:sort]) ? params[:sort] : "expenses.date"
  end
  helper_method :sort_column

  private def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "desc"
  end

  private def set_active_nav
    @active_nav = 'expenses'
  end

  private def expense_params
    @expense_params ||= params.require(:expense).permit(
      :expense_type, :description, :seller, :date, :receipt, :value
    )
  end

  private def expense
    @expense ||= current_account.expenses.find_by(id: params[:id])
    @expense ||= current_account.expenses.new expense_params
  end
  helper_method :expense
end
