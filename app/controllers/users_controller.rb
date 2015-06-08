class UsersController < ApplicationController
  def disable_otp
    current_user.otp_required_for_login = false
    current_user.save!
    redirect_to :back
  end

  def enable_otp
    current_user.otp_secret = User.generate_otp_secret
    current_user.otp_required_for_login = true
    current_user.save!
    redirect_to :back
  end
end
