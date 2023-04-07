# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  before_action :set_active_nav

  layout "landing_page"

  private def set_active_nav
    @active_nav = "sessions"
  end
end
