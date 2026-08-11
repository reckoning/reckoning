# frozen_string_literal: true

module Api
  module V1
    # Two-factor enrollment for the signed-in user.
    class OtpController < ::Api::BaseController
      before_action :set_user

      # Starts enrollment by minting a secret. Idempotent while 2FA is off;
      # once it is on, the existing secret is kept so an enrolled
      # authenticator app doesn't stop working.
      def create
        return render :show if @user.otp_required_for_login?

        @user.otp_secret = ::User.generate_otp_secret
        @user.save!

        render :show, status: :created
      end

      # SVG rather than JSON: the client renders it directly.
      def qrcode
        uri = @user.otp_provisioning_uri(@user.email, issuer: Rails.configuration.app.name)
        qr = RQRCode::QRCode.new(uri, level: :l)

        send_data qr.as_svg(color: "428bca"), type: "image/svg+xml", disposition: "inline"
      end

      def enable
        return render_invalid_attempt unless @user.validate_and_consume_otp!(otp_attempt)

        @user.otp_required_for_login = true
        @codes = @user.generate_otp_backup_codes!
        @user.save!

        render :codes
      end

      def disable
        return render_invalid_attempt unless @user.validate_and_consume_otp!(otp_attempt)

        @user.otp_secret = ::User.generate_otp_secret
        @user.otp_required_for_login = false
        @user.save!

        render :show
      end

      # Invalidates the previous set, so this is only offered once 2FA is on.
      def backup_codes
        unless @user.otp_required_for_login?
          return render json: {
            code: "otp.not_enabled",
            message: I18n.t("validation_error.otp.not_enabled")
          }, status: :bad_request
        end

        @codes = @user.generate_otp_backup_codes!
        @user.save!

        render :codes
      end

      private def render_invalid_attempt
        render json: {
          code: "otp.invalid_attempt",
          message: I18n.t("validation_error.otp.invalid_attempt")
        }, status: :bad_request
      end

      private def set_user
        @user = current_user
        authorize! :update, @user
      end

      private def otp_attempt
        openapi_params(::V1::Schemas::Inputs::OtpInput)[:otp_attempt]
      end
    end
  end
end
