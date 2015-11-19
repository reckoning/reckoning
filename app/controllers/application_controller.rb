class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  check_authorization unless: :unauthorized_controllers

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  before_action :authenticate_user!, :set_default_nav
  before_action :configure_permitted_parameters, if: :devise_controller?

  private def current_account
    @current_account ||= begin
      if current_user.present?
        current_user.account
      elsif request.subdomain.present? && request.subdomain != "www" && request.subdomain != "api"
        Account.where(subdomain: request.subdomain).first
      end
    end
  end
  helper_method :current_account

  private def unauthorized_controllers
    devise_controller?
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

  private def nav_aside?
    nav_layout == "aside"
  end
  helper_method :nav_aside?

  private def nav_layout
    if user_signed_in?
      # if current_user.layout == "aside"
        "aside"
      # else
        # "full_layout"
      # end
    else
      "top"
    end
  end
  helper_method :nav_layout

  private def invoice_limit_reached?
    !current_user.admin? && Rails.application.secrets[:base]["demo"] && current_account.invoices.count >= 2
  end
  helper_method :invoice_limit_reached?

  protected def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) << :otp_attempt
  end
end
