# frozen_string_literal: true

module Api
  module V1
    # Account lockout. `lock_strategy` is `:failed_attempts` and
    # `unlock_strategy` is `:email`, so this is the only way back in for a
    # locked account.
    class UnlocksController < ::Api::BaseController
      skip_authorization_check
      skip_before_action :authenticate_user!
      skip_forgery_protection

      # Always reports success: whether an address has an account is not
      # something an unauthenticated caller should be able to probe.
      def create
        User.send_unlock_instructions(email: unlock_request_params[:email])

        render json: {message: I18n.t("devise.unlocks.send_paranoid_instructions")}
      end

      def update
        @user = User.unlock_access_by_token(unlock_params[:unlock_token])

        if @user.errors.empty?
          render json: {message: I18n.t("devise.unlocks.unlocked")}
        else
          render json: ValidationError.new("unlock.update", @user.errors), status: :bad_request
        end
      end

      private def unlock_request_params
        @unlock_request_params ||= openapi_params(::V1::Schemas::Inputs::UnlockRequestInput)
      end

      private def unlock_params
        @unlock_params ||= openapi_params(::V1::Schemas::Inputs::UnlockInput)
      end
    end
  end
end
