# encoding: UTF-8
class ApplicationController < ActionController::Base
  add_flash_types :error, :warning

  helper :all

  check_authorization unless: :unauthorized_controllers

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, warning: exception.message
  end

  helper_method :sort_direction, :backend?

  protect_from_forgery

  before_filter :authenticate_user!, :set_default_nav

  private def set_default_nav
    @active_nav = 'home'
  end

  private def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  private def unauthorized_controllers
    devise_controller?
  end

  private def backend?
    self.class.to_s.split("::").first=="Backend"
  end

  private def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private def registration_enabled?
    Settings.base.registration.to_s.to_bool
  end
  helper_method :registration_enabled?

  private def invoice_limit_reached?
    !current_user.admin? && Settings.demo && Invoice.count >= 1
  end
  helper_method :invoice_limit_reached?
end
