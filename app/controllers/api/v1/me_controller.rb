# frozen_string_literal: true

module Api
  module V1
    # The signed-in user's own record. Distinct from `users#current`, which is
    # admin-only because it authorizes against the whole User class.
    class MeController < ::Api::BaseController
      def show
        @user = current_user
        authorize! :read, @user
      end

      def update
        @user = current_user
        authorize! :update, @user

        # `update_without_password` so a profile edit doesn't require or clear
        # the password; changing it is a separate flow.
        return render :show if @user.update_without_password(me_params)

        render json: ValidationError.new("user.update", @user.errors), status: :bad_request
      end

      # Separate from #update: this one requires the current password and
      # re-signs the session, which a profile edit must not do.
      def update_password
        @user = current_user
        authorize! :update, @user

        if @user.update_with_password(password_params)
          bypass_sign_in(@user)
          render :show
        else
          render json: ValidationError.new("password.update", @user.errors), status: :bad_request
        end
      end

      private def password_params
        @password_params ||= openapi_params(::V1::Schemas::Inputs::PasswordChangeInput)
      end

      private def me_params
        @me_params ||= openapi_params(::V1::Schemas::Inputs::MeInput)
      end
    end
  end
end
