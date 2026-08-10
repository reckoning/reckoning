# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    include ::AccountsConcern
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection

    # `ActionController::API` ships without forgery protection, which is fine
    # for the JWT clients but not for the SPA, which authenticates by session
    # cookie. `same_site: :lax` on that cookie is not enough on its own here:
    # `cookie_domain` resolves to `:all`, so the cookie is shared across every
    # account subdomain and SameSite treats siblings as same-site.
    protect_from_forgery with: :exception, unless: :token_authenticated?

    # `config.action_controller.allow_forgery_protection` is applied at boot to
    # controllers that already include RequestForgeryProtection — which
    # `ActionController::API` does not. Without this, the test environment's
    # blanket disable would silently not apply here. Defaults to on, so an
    # environment that says nothing stays protected.
    forgery_protection = Rails.application.config.action_controller.allow_forgery_protection
    self.allow_forgery_protection = forgery_protection.nil? || forgery_protection

    before_action :authenticate_user!

    respond_to :json

    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      render json: {message: exception.message}, status: :forbidden
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      render json: {
        code: "invalid_authenticity_token",
        message: I18n.t("errors.invalid_authenticity_token", default: "Invalid authenticity token")
      }, status: :unprocessable_entity
    end

    # Bearer-token clients carry no cookie, so there is nothing for a
    # cross-site request to ride on and nothing to verify.
    private def token_authenticated?
      request.headers["Authorization"].present?
    end

    # Permit params from an OpenAPI input component. The schema spells
    # properties camelCase (matching the wire format jbuilder emits), while
    # ActiveRecord wants snake_case — so both the incoming keys and the permit
    # list derived from the component are underscored before they meet.
    private def openapi_params(component)
      params
        .deep_transform_keys { |key| key.to_s.underscore }
        .permit(*underscore_permit_list(component.permitted_params))
    end

    private def underscore_permit_list(list)
      list.map do |entry|
        next entry.to_s.underscore.to_sym unless entry.is_a?(Hash)

        entry.to_h do |key, value|
          nested = value.is_a?(Array) ? underscore_permit_list(value) : value
          [key.to_s.underscore.to_sym, nested]
        end
      end
    end

    private def not_found(message = I18n.t("messages.record_not_found.base"))
      render json: {code: "not_found", message: message}, status: :not_found
    end

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
    end
  end
end
