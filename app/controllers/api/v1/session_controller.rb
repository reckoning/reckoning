module Api
  module V1
    class SessionController < Api::BaseController
      around_action :authenticate_user_from_token!, except: [:create]
      respond_to :json

      def create
        authorize! :index, Task
        if user && user.valid_password?(user_params.fetch(:password))
          sign_in("user", user)
          render json: user, status: :ok
        else
          warden.custom_failure!
          render json: ValidationError.new("sessions.authentication"), status: :unauthorized
        end
      end

      private def user_params
        params.permit(:email, :password)
      end

      private def user
        User.find_for_database_authentication(email: user_params.fetch(:email))
      end
    end
  end
end
