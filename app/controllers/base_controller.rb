# frozen_string_literal: true

class BaseController < ApplicationController
  skip_authorization_check
  before_action :authenticate_user!, only: []

  def index
    @active_nav = "home"
    if user_signed_in?
      # The SPA's dashboard is the root path, so this renders the shell rather
      # than sending the browser somewhere else for it.
      render template: "spa/index", layout: "spa"
    elsif current_account.present?
      redirect_to new_user_session_path
    else
      welcome
    end
  end

  def impressum
    @active_nav = "impressum"
  end

  def privacy
    @active_nav = "privacy"
  end

  def terms
    @active_nav = "terms"
  end

  private def welcome
    @active_nav = "welcome"
    render "welcome", layout: "landing_page"
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
