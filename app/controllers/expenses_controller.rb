# frozen_string_literal: true

class ExpensesController < ApplicationController
  include ResourceHelper
  include ExpensesHelper

  before_action :set_active_nav
  before_action :store_current_params, only: [:index]

  def index
    authorize! :read, :expenses
    expenses = current_account.expenses
      .filter_result(filter_params)

    respond_to do |format|
      format.csv do
        send_data expenses.to_csv
      end
      format.pdf do
        render ExpensePdf.new(current_account, expenses, filter_params).pdf
      end
      format.html do
        year = filter_params.fetch(:year, nil)

        normalized_expenses = Expense.normalized(expenses.without_insurances.to_a, year: year)
        normalized_expenses = Expense.normalized(expenses.to_a, year: year) if filter_params[:type] == "insurances"

        open_afa_expenses = current_account.expenses.filter_result(filter_params).filter_type(:afa).sum do |expense|
          expense.afa_value(year&.to_i || Time.current.year)
        end

        @expenses_sum = normalized_expenses.sum do |expense|
          next 0 if expense.expense_type == "afa"

          expense.usable_value(year&.to_i || Time.current.year)
        end + open_afa_expenses

        @expenses_vat_sum = normalized_expenses.sum(&:vat_value)

        @expenses = expenses.order(sort_column.to_sym => sort_direction, :created_at => :desc)
          .page(params.fetch(:page, nil))
          .per(40)
      end
    end
  end

  def new
    authorize! :create, Expense
    @expense = current_account.expenses.new(prefill_params)
  end

  def edit
    authorize! :create, expense
  end

  def create
    authorize! :create, Expense
    if expense.save
      redirect_to "#{expenses_path(stored_params(:index))}#expense-#{expense.id}", flash: {success: resource_message(:expense, :create, :success)}
    else
      flash.now[:alert] = resource_message(:expense, :create, :failure)
      render "new"
    end
  end

  def update
    authorize! :update, expense
    if expense.update(expense_params)
      redirect_to "#{expenses_path(stored_params(:index))}#expense-#{expense.id}", flash: {success: resource_message(:expense, :update, :success)}
    else
      flash.now[:alert] = resource_message(:expense, :update, :failure)
      render "edit"
    end
  end

  def destroy
    authorize! :destroy, expense

    if expense.destroy
      flash.now[:success] = resource_message(:expense, :destroy, :success)
    else
      flash.now[:alert] = resource_message(:expense, :destroy, :failure)
    end

    respond_to do |format|
      format.js { render json: {}, status: :ok }
      format.html { redirect_to expenses_path(stored_params(:index)) }
    end
  end

  private def filter_params
    params.permit(:year, :type, :quarter, :month, :query)
  end
  helper_method :filter_params

  private def sort_column
    Expense.column_names.include?(params[:sort]) ? params[:sort] : "expenses.date"
  end
  helper_method :sort_column

  private def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  private def set_active_nav
    @active_nav = "expenses"
  end

  private def expense_params
    @expense_params ||= params.require(:expense).permit(
      :expense_type, :afa_type_id, :description, :seller, :date, :receipt, :remove_receipt, :value,
      :private_use_percent, :vat_percent, :interval, :started_at, :ended_at
    )
  end

  private def prefill_params
    @prefill_params ||= params.permit(
      :expense_type, :afa_type_id, :description, :seller, :date, :value, :private_use_percent,
      :vat_percent, :interval, :started_at, :ended_at
    )
  end

  private def expense
    @expense ||= current_account.expenses.find_by(id: params[:id])
    @expense ||= current_account.expenses.new expense_params
  end
  helper_method :expense
end
