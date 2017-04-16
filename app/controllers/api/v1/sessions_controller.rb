# encoding: utf-8
# frozen_string_literal: true
module Api
  module V1
    class SessionsController < Api::BaseController
      skip_authorization_check
      before_action :authenticate_user_from_token!, except: [:create]
      before_action :authenticate_user!, except: [:create]

      respond_to :json

      def create
        resource = User.find_for_database_authentication(email: login_params[:email])
        return invalid_login_attempt unless resource

        if resource.valid_password?(login_params[:password]) && validate_otp(resource)
          sign_in(:user, resource, store: false)
          token = AuthToken.create(
            user_id: resource.id,
            scope: :api,
            user_agent: request.user_agent,
            description: login_params[:description]
          )
          render json: { auth_token: token.token }
          return
        end
        invalid_login_attempt
      end

      def destroy
        token = AuthToken.find_by(user_id: current_user.id, scope: :api)
        token && token.destroy
        render json: { code: "sessions.destroy", message: I18n.t("devise.sessions.signed_out") }
      end

      private def validate_otp(resource)
        return true unless resource.otp_required_for_login
        return if login_params[:otp_token].nil?
        resource.validate_and_consume_otp!(login_params[:otp_token])
      end

      private def login_params
        @login_params ||= params.permit(:email, :password, :otp_token, :description)
      end

      private def invalid_login_attempt
        render json: { code: "session.create", message: I18n.t("devise.failure.invalid") }, status: :bad_request
      end
    end
  end
end
