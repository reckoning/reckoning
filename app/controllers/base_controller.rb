class BaseController < ApplicationController
  skip_authorization_check
  before_filter :authenticate_user!, :only => [:fail]

  def index
    if user_signed_in?
      dashboard
    else
      welcome
    end
  end

  def dashboard
    @charged_invoices = current_user.invoices.order('date DESC').charged
    @paid_invoices = current_user.invoices.order('date DESC').paid.year(Time.now.year)
    @last_invoices = current_user.invoices.order('date DESC').paid.year(Time.now.year - 1)

    render 'dashboard'
  end

  def welcome
    @active_nav = 'welcome'
    render 'welcome'
  end

end
