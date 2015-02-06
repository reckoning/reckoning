class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  add_flash_types :info, :warning

  check_authorization unless: :unauthorized_controllers

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, warning: exception.message
  end

  before_action :authenticate_user!, :set_default_nav

  private

  private def current_account
    @current_account ||= current_user && current_user.account
  end
  helper_method :current_account

  private def unauthorized_controllers
    devise_controller? || is_a?(RailsAssetLocalization::LocalesController)
  end

  private def set_default_nav
    @active_nav = 'home'
  end

  private def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "desc"
  end
  helper_method :sort_direction

  private def backend?
    self.class.to_s.split("::").first == "Backend"
  end
  helper_method :backend?

  private def registration_enabled?
    Rails.application.secrets[:base]["registration"]
  end
  helper_method :registration_enabled?

  private def invoice_limit_reached?
    !current_user.admin? && Rails.application.secrets[:base]["demo"] && current_account.invoices.count >= 2
  end
  helper_method :invoice_limit_reached?
end
