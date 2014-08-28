class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  add_flash_types :info, :warning

  check_authorization unless: :unauthorized_controllers

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, warning: exception.message
  end

  before_filter :authenticate_user!, :set_default_nav

  private

  def unauthorized_controllers
    devise_controller? || is_a?(RailsAssetLocalization::LocalesController)
  end

  def set_default_nav
    @active_nav = 'home'
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
  helper_method :sort_direction

  def backend?
    self.class.to_s.split("::").first=="Backend"
  end
  helper_method :backend?

  def registration_enabled?
    Rails.application.secrets[:base]["registration"]
  end
  helper_method :registration_enabled?

  def invoice_limit_reached?
    !current_user.admin? && Rails.application.secrets[:base]["demo"] && current_user.invoices.count >= 2
  end
  helper_method :invoice_limit_reached?
end
