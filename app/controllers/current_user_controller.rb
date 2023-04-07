# frozen_string_literal: true

class CurrentUserController < ApplicationController
  def otp
    authorize! :update, current_user
    return if current_user.reload.otp_required_for_login?

    current_user.otp_secret = User.generate_otp_secret
    current_user.save
  end

  def otp_qrcode
    authorize! :update, current_user
    uri = current_user.otp_provisioning_uri(current_user.email, issuer: Rails.configuration.app.name)
    qr = RQRCode.render_qrcode(uri, :png, level: :l, unit: 6)
    send_data qr, type: "image/png", disposition: "inline"
  end

  def otp_backup_codes
    authorize! :update, current_user
    if current_user.reload.otp_required_for_login?
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!
      flash.now[:success] = I18n.t(:"messages.backup_codes", scope: "devise.otp")
      render "otp"
    else
      redirect_to "#{edit_user_registration_path}#security"
    end
  end

  def enable_otp
    authorize! :update, current_user
    if current_user.validate_and_consume_otp!(otp_attempt)
      current_user.otp_required_for_login = true
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!
      flash.now[:success] = I18n.t(:"messages.enable.success", scope: "devise.otp")
    else
      flash.now[:alert] = I18n.t(:"messages.enable.failure", scope: "devise.otp")
    end
    render "otp"
  end

  def disable_otp
    authorize! :update, current_user
    if current_user.validate_and_consume_otp!(otp_attempt)
      current_user.otp_secret = User.generate_otp_secret
      current_user.otp_required_for_login = false
      current_user.save!
      redirect_to "#{edit_user_registration_path}#security", flash: {success: I18n.t(:"messages.disable.success", scope: "devise.otp")}
    else
      flash.now[:alert] = I18n.t(:"messages.disable.failure", scope: "devise.otp")
      render "otp"
    end
  end

  private def otp_attempt
    params.fetch(:user, {}).fetch(:otp_attempt, nil)
  end
end
