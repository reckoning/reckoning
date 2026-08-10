# frozen_string_literal: true

module Api
  module V1
    # Signup: creates an account together with its first user.
    class RegistrationsController < ::Api::BaseController
      skip_authorization_check
      skip_before_action :authenticate_user!
      skip_forgery_protection

      before_action :check_registration_enabled

      def create
        @account = Account.new(account_params)

        if @account.save
          render :create, status: :created
        else
          render json: ValidationError.new("account.create", @account.errors), status: :bad_request
        end
      end

      private def check_registration_enabled
        return if Rails.configuration.app.registration

        render json: {
          code: "registration.disabled",
          message: I18n.t("validation_error.account.registration_disabled")
        }, status: :forbidden
      end

      private def account_params
        @account_params ||= openapi_params(::V1::Schemas::Inputs::RegistrationInput)
      end
    end
  end
end
