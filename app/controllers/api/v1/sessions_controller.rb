# frozen_string_literal: true

module Api
  module V1
    class SessionsController < Api::BaseController
      include ActionController::HttpAuthentication::Token

      skip_authorization_check

      # This is where a client without a session obtains its token, so there is
      # no cookie to protect and no token it could have been given yet.
      # Requiring one here would lock out every non-browser client.
      skip_forgery_protection only: [:create]

      before_action :authenticate_user!, except: [:create]

      respond_to :json

      def create
        resource = User.find_for_database_authentication(email: login_params[:email])
        return invalid_login_attempt unless resource

        if resource.valid_password?(login_params[:password]) && validate_otp(resource)
          # Stores the session, so the SPA gets a cookie from the same endpoint
          # that hands native clients a token. Each ignores the other's half.
          sign_in(:user, resource)
          render json: {auth_token: JsonWebToken.encode(new_auth_token(resource.id).to_jwt_payload)}
          return
        end
        invalid_login_attempt
      end

      def destroy
        revoke_auth_token
        sign_out(current_user)

        render json: {code: "sessions.destroy", message: I18n.t("devise.sessions.signed_out")}
      end

      # Only token clients have a token to revoke; a cookie client just needs
      # the session cleared.
      private def revoke_auth_token
        return if request.headers["Authorization"].blank?

        AuthToken.find_by(user_id: current_user.id, token: jwt_token[:token])&.destroy
      end

      private def new_auth_token(user_id)
        @new_auth_token ||= AuthToken.create(
          user_id: user_id,
          user_agent: request.user_agent,
          description: login_params[:description],
          expires: login_params[:expires]
        )
      end

      private def jwt_token
        @jwt_token ||= begin
          auth_params, _options = token_and_options(request)
          JsonWebToken.decode(auth_params)
        end
      end

      private def validate_otp(resource)
        return true unless resource.otp_required_for_login
        return if login_params[:otp_token].nil?

        resource.validate_and_consume_otp!(login_params[:otp_token])
      end

      private def login_params
        @login_params ||= params.permit(:email, :password, :otp_token, :description, :expires)
      end

      private def invalid_login_attempt
        render json: {code: "session.create", message: I18n.t("devise.failure.invalid")}, status: :bad_request
      end
    end
  end
end
