# encoding: utf-8
# frozen_string_literal: true
require 'json_web_token'

module Api
  class BaseController < ActionController::Base
    include ActionController::HttpAuthentication::Token
    before_action :authenticate_user_from_token!
    before_action :authenticate_user!

    respond_to :json

    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      render json: { message: exception.message }, status: :forbidden
    end

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
    end
    helper_method :resource_message

    private def authenticate_user_from_token!
      auth_params, _options = token_and_options(request)
      auth_token = JsonWebToken.decode(auth_params)
      if auth_token && auth_token[:user_id]
        user = User.find(auth_token[:user_id])
        token = AuthToken.find_by(user_id: auth_token[:user_id], token: auth_params, scope: [:api, :system])
      end

      if user && token && Devise.secure_compare(token.token, auth_params)
        sign_in user, store: false
      else
        render json: { code: "unauthorized", message: I18n.t("devise.failure.unauthenticated") }, status: :unauthorized
        return
      end
    end

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
  end
end
