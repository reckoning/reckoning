class BaseController < ApplicationController
  include NumberHelper
  skip_authorization_check
  before_action :authenticate_user!, only: [:fail]

  def index
    if user_signed_in?
      dashboard
    elsif current_account.present?
      redirect_to new_user_session_path
    else
      welcome
    end
  end

  def dashboard
    @charged_invoices = current_account.invoices.includes(:customer, :project).order('date DESC').charged
    @paid_invoices = current_account.invoices.includes(:customer, :project).order('date DESC').paid.year(Time.zone.now.year)
    @last_invoices = current_account.invoices.includes(:customer, :project).order('date DESC').paid.year(Time.zone.now.year - 1)
    @budgets = current_account.projects.with_budget.includes(:customer, :tasks, :timers).order('tasks.updated_at DESC')
    scope = current_account.invoices.paid_or_charged.where(date: (Time.zone.now - 1.year).beginning_of_year..Time.zone.now.end_of_year)
    @invoices_chart_data = Charts::InvoicesService.new(scope).data
    render 'dashboard'
  end

  def welcome
    @active_nav = 'welcome'
    render 'welcome'
  end
end
