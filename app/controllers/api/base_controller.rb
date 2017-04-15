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

    def decoded_auth_token
      auth_token, _options = token_and_options(request)
      @decoded_auth_token ||= JsonWebToken.decode(auth_token)
    end

    private def authenticate_user_from_token!
      user ||= User.find(decoded_auth_token[:id]) if decoded_auth_token

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
  end
end
