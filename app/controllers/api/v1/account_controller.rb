# frozen_string_literal: true

module Api
  module V1
    class AccountController < ::Api::BaseController
      def show
        @account = current_account
        authorize! :update, @account
      end

      def update
        @account = current_account
        authorize! :update, @account

        return render :show if @account.update(account_params)

        render json: ValidationError.new("account.update", @account.errors), status: :bad_request
      end

      private def account_params
        @account_params ||= openapi_params(::V1::Schemas::Inputs::AccountInput)
      end
    end
  end
end
