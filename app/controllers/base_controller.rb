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

  def impressum
    @active_nav = 'impressum'
  end

  def privacy
    @active_nav = 'privacy'
  end

  def terms
    @active_nav = 'terms'
  end

  private

  def dashboard
    @charged_invoices = current_account.invoices.order('date DESC').charged
    @paid_invoices = current_account.invoices.order('date DESC').paid.year(Time.zone.now.year)
    @last_invoices = current_account.invoices.order('date DESC').paid.year(Time.zone.now.year - 1)
    @budgets = current_account.projects.with_budget.includes(:tasks).order('tasks.updated_at DESC')
    scope = current_account.invoices.paid.where(date: (Time.zone.now - 1.year).beginning_of_year..Time.zone.now.end_of_year)
    @invoices_chart_data = Charts::InvoicesService.new(scope).data unless scope.count.zero?
    render 'dashboard'
  end

  def welcome
    @active_nav = 'welcome'
    render 'welcome'
  end

  def contact
    Contact.new
  end
  helper_method :contact

  def contact_cookie
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

  def plans
    plans = []

    plan_list = Stripe::Plan.all
    plan_list.data.each do |plan|
      plans << plan
    end

    plans = plans.sort_by(&:amount)

    plans
  end
  helper_method :plans
end
