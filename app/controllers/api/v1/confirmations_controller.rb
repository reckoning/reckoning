# frozen_string_literal: true

module Api
  module V1
    # Email confirmation. `reconfirmable` is on, so this also serves an address
    # change, not just signup.
    class ConfirmationsController < ::Api::BaseController
      skip_authorization_check
      skip_before_action :authenticate_user!
      skip_forgery_protection

      # Always reports success: whether an address has an account is not
      # something an unauthenticated caller should be able to probe.
      def create
        User.send_confirmation_instructions(email: confirmation_request_params[:email])

        render json: {message: I18n.t("devise.confirmations.send_paranoid_instructions")}
      end

      def update
        @user = User.confirm_by_token(confirmation_params[:confirmation_token])

        if @user.errors.empty?
          render json: {message: I18n.t("devise.confirmations.confirmed")}
        else
          render json: ValidationError.new("confirmation.update", @user.errors), status: :bad_request
        end
      end

      private def confirmation_request_params
        @confirmation_request_params ||= openapi_params(::V1::Schemas::Inputs::ConfirmationRequestInput)
      end

      private def confirmation_params
        @confirmation_params ||= openapi_params(::V1::Schemas::Inputs::ConfirmationInput)
      end
    end
  end
end
