# frozen_string_literal: true

class BaseController < ApplicationController
  skip_authorization_check
  before_action :authenticate_user!, only: []

  def index
    @active_nav = "home"
    # The root path is the SPA's: the dashboard for whoever is signed in, the
    # welcome page for everyone else. An account's own subdomain has no
    # welcome page to show — it is one account's sign-in.
    if user_signed_in? || current_account.blank?
      render template: "spa/index", layout: "spa"
    else
      redirect_to new_user_session_path
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
