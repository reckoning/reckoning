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
end
