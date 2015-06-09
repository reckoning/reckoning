class CurrentUserController < ApplicationController
  def otp
    authorize! :update, current_user
  end

  def otp_qrcode
    authorize! :update, current_user
    uri = current_user.otp_provisioning_uri(current_user.email, issuer: Rails.application.secrets[:devise_otp_issuer])
    qr = RQRCode.render_qrcode(uri, :png, level: :l, unit: 6)
    send_data qr, type: 'image/png', disposition: 'inline'
  end

  def otp_backup_codes
    authorize! :update, current_user
    if current_user.reload.otp_required_for_login?
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!
      render "otp"
    else
      redirect_to "#{edit_user_registration_path}#security"
    end
  end

  def enable_otp
    authorize! :update, current_user
    if current_user.valid_otp?(otp_attempt)
      current_user.otp_required_for_login = true
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!
      render "otp", flash: { success: I18n.t(:"messages.enable.success", scope: 'devise.otp') }
    else
      render "otp", alert: I18n.t(:"messages.enable.failure", scope: 'devise.otp')
    end
  end

  def disable_otp
    authorize! :update, current_user
    if current_user.valid_otp?(otp_attempt)
      current_user.otp_secret = User.generate_otp_secret
      current_user.otp_required_for_login = false
      current_user.save!
      redirect_to "#{edit_user_registration_path}#security", flash: { success: I18n.t(:"messages.disable.success", scope: 'devise.otp') }
    else
      render "otp", alert: I18n.t(:"messages.disable.failure", scope: 'devise.otp')
    end
  end

  private def otp_attempt
    params.fetch(:user, {}).fetch(:otp_attempt, nil)
  end
end
