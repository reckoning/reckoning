# frozen_string_literal: true

class BaseController < ApplicationController
  include NumberHelper
  skip_authorization_check
  before_action :authenticate_user!, only: []

  def index
    @active_nav = 'home'
    if user_signed_in?
      dashboard
    elsif current_account.present?
      redirect_to new_user_session_path
    else
      welcome
    end
  end

  def impressum
    @active_nav = 'impressum'
  end

  def privacy
    @active_nav = 'privacy'
  end

  def terms
    @active_nav = 'terms'
  end

  private def dashboard
    @charged_invoices = current_account.invoices.includes(:customer, :project).order('date DESC').charged
    @paid_invoices = current_account.invoices.includes(:customer, :project).order('date DESC').paid_in_year(Time.zone.now.year)
    @last_invoices = current_account.invoices.includes(:customer, :project).order('date DESC').paid_in_year(Time.zone.now.year - 1)
    @budgets = current_account.projects.active.with_budget.includes(:customer, :tasks, :timers).order('tasks.updated_at DESC')
    scope = current_account.invoices.paid_or_charged.where(date: 1.year.ago.beginning_of_year..Time.zone.now.end_of_year)
    @invoices_chart_data = Charts::InvoicesService.new(scope).data
    @expenses = Expense.normalized(current_account.expenses.without_insurances.year(Time.zone.now.year).to_a, year: Time.zone.now.year)
    @last_expenses = Expense.normalized(current_account.expenses.without_insurances.year(Time.zone.now.year - 1).to_a, year: Time.zone.now.year - 1)
    render 'dashboard'
  end

  private def welcome
    @active_nav = 'welcome'
    render 'welcome', layout: 'landing_page'
  end

  private def contact
    Contact.new
  end
  helper_method :contact

  private def contact_cookie
    return if cookies[:_reckoning_contact].blank?

    contact = Contact.where(email: cookies.signed[:_reckoning_contact]).first
    if contact.blank?
      cookies.delete :_reckoning_contact
      false
    else
      true
    end
  end
  helper_method :contact_cookie

  private def plans
    plans = []

    plan_list = Stripe::Plan.all
    plan_list.data.each do |plan|
      plans << plan
    end

    plans.sort_by(&:amount)
  end
  helper_method :plans
end
