# encoding: utf-8
# frozen_string_literal: true
require 'json_web_token'

module Api
  class BaseController < ActionController::Base
    include ActionController::HttpAuthentication::Token
    around_action :authenticate_user_from_token!
    respond_to :json

    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      render json: { message: exception.message }, status: :forbidden
    end

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
    end
    helper_method :resource_message

    attr_reader :current_account
    helper_method :current_account

    private def authenticate_user_from_token!
      auth_params, _options = token_and_options(request)
      user = lookup_by_jwt(auth_params)
      user ||= lookup_by_auth_token(auth_params)

      if user
        sign_in user, store: false
        @current_user = user
        @current_account = user.account

        yield
      else
        message = "HTTP Token: Access denied."
        render json: { code: "authentication.missing", message: message }, status: :forbidden
      end
    end

    private def decoded_auth_token(auth_params)
      @decoded_auth_token ||= JsonWebToken.decode(auth_params)
    end

    private def lookup_by_jwt(auth_params)
      token = decoded_auth_token(auth_params)
      User.find(token[:id]) if token
    end

    private def lookup_auth_token(user, auth_token)
      AuthToken.where(user_id: user.id).to_a.find do |token|
        Devise.secure_compare(token, auth_token)
      end
    end

    private def lookup_by_auth_token(auth_params)
      user_id, auth_token = auth_params && auth_params.split(':', 2)
      user = user_id && User.find(user_id)

      return if !user || !lookup_auth_token(user, auth_token)

      user
    end
  end
end
