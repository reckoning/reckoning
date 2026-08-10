# frozen_string_literal: true

json.otp_required @user.otp_required_for_login
json.provisioning_uri @user.otp_provisioning_uri(@user.email, issuer: Rails.configuration.app.name)
