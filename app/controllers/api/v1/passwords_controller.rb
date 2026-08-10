# frozen_string_literal: true

module Api
  module V1
    # The forgot-password flow. Changing a known password while signed in is
    # `PATCH /me/password`.
    class PasswordsController < ::Api::BaseController
      skip_authorization_check
      skip_before_action :authenticate_user!
      skip_forgery_protection

      # Always reports success: whether an address has an account is not
      # something an unauthenticated caller should be able to probe.
      def create
        User.send_reset_password_instructions(email: reset_request_params[:email])

        render json: {message: I18n.t("devise.passwords.send_paranoid_instructions")}
      end

      def update
        @user = User.reset_password_by_token(reset_params)

        if @user.errors.empty?
          render json: {message: I18n.t("devise.passwords.updated_not_active")}
        else
          render json: ValidationError.new("password.update", @user.errors), status: :bad_request
        end
      end

      private def reset_request_params
        @reset_request_params ||= openapi_params(::V1::Schemas::Inputs::PasswordResetRequestInput)
      end

      private def reset_params
        @reset_params ||= openapi_params(::V1::Schemas::Inputs::PasswordResetInput)
      end
    end
  end
end
