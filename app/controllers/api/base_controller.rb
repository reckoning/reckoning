module Api
  class BaseController < ActionController::Base
    before_filter :authenticate_user_from_token!

    private

    def authenticate_user_from_token!
      user_email = params[:email].presence
      user = user_email && User.find_by_email(user_email)

      if user && Devise.secure_compare(user.authentication_token, params[:token])
        sign_in user, store: false
      else
        render json: {}
      end
    end
  end
end
