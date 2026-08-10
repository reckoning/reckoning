# frozen_string_literal: true

require "openapi_helper"

# Each OTP route gets its own class: they are all parameterless, and
# `assert_api_response` resolves a verb to the first matching api_path.
module Api
  module V1
    class OtpEnrollmentTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me/otp" do
        post("Begin two-factor enrollment") do
          operationId "createOtpEnrollment"
          tags "Otp"
          produces "application/json"

          response(201, "secret generated") do
            schema ::V1::Schemas::OtpEnrollment
          end

          response(200, "already enrolled") do
            schema ::V1::Schemas::OtpEnrollment
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }

      it "is unauthorized when signed out" do
        assert_api_response :post, 401
      end

      it "mints a secret and returns a provisioning uri" do
        sign_in data

        assert_api_response :post, 201 do
          assert_match(/^otpauth:\/\//, parsed_body["provisioningUri"])
        end

        assert data.reload.otp_secret.present?
      end

      # Re-running enrollment must not rotate the secret out from under an
      # authenticator app that is already set up.
      it "keeps the existing secret once two-factor is on" do
        data.otp_secret = ::User.generate_otp_secret
        data.otp_required_for_login = true
        data.save!
        secret = data.reload.otp_secret

        sign_in data

        assert_api_response :post, 200

        assert_equal secret, data.reload.otp_secret
      end
    end

    class OtpQrcodeTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me/otp/qrcode" do
        get("Provisioning QR code") do
          operationId "otpQrcode"
          tags "Otp"
          produces "image/svg+xml"

          response(200, "successful") do
            schema type: :string, format: :binary
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }

      # Raw requests rather than assert_api_response: the body is SVG, not
      # JSON, so there is no response schema to validate against.
      it "is unauthorized when signed out" do
        get "/api/v1/me/otp/qrcode"

        assert_response :unauthorized
      end

      it "renders an SVG for the provisioning uri" do
        data.otp_secret = ::User.generate_otp_secret
        data.save!
        sign_in data

        get "/api/v1/me/otp/qrcode"

        assert_response :ok
        assert_equal "image/svg+xml", response.media_type
        assert_includes response.body, "<svg"
      end
    end

    class OtpEnableTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me/otp/enable" do
        post("Turn two-factor on") do
          operationId "enableOtp"
          tags "Otp"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::OtpInput}
          }

          response(200, "enabled") do
            schema ::V1::Schemas::OtpBackupCodes
          end

          response(400, "invalid code") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }

      before do
        data.otp_secret = ::User.generate_otp_secret
        data.save!
      end

      it "enables two-factor and returns backup codes" do
        sign_in data

        assert_api_response :post, 200, body: {otp_attempt: data.current_otp} do
          assert parsed_body["otpRequired"]
          assert_equal 10, parsed_body["backupCodes"].size
        end

        assert data.reload.otp_required_for_login?
      end

      it "rejects a wrong code" do
        sign_in data

        assert_api_response :post, 400, body: {otp_attempt: "000000"} do
          assert_equal "otp.invalid_attempt", parsed_body["code"]
        end

        refute data.reload.otp_required_for_login?
      end
    end

    class OtpDisableTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me/otp/disable" do
        post("Turn two-factor off") do
          operationId "disableOtp"
          tags "Otp"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::OtpInput}
          }

          response(200, "disabled") do
            schema ::V1::Schemas::OtpEnrollment
          end

          response(400, "invalid code") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }

      before do
        data.otp_secret = ::User.generate_otp_secret
        data.otp_required_for_login = true
        data.save!
      end

      it "disables two-factor with a valid code" do
        sign_in data

        assert_api_response :post, 200, body: {otp_attempt: data.current_otp}

        refute data.reload.otp_required_for_login?
      end

      it "rejects a wrong code and stays enabled" do
        sign_in data

        assert_api_response :post, 400, body: {otp_attempt: "000000"}

        assert data.reload.otp_required_for_login?
      end
    end

    class OtpBackupCodesTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me/otp/backup_codes" do
        post("Regenerate backup codes") do
          operationId "regenerateOtpBackupCodes"
          tags "Otp"
          produces "application/json"

          response(200, "regenerated") do
            schema ::V1::Schemas::OtpBackupCodes
          end

          response(400, "two-factor not enabled") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }

      it "regenerates a fresh set" do
        data.otp_secret = ::User.generate_otp_secret
        data.otp_required_for_login = true
        data.save!
        previous = data.generate_otp_backup_codes!
        data.save!

        sign_in data

        assert_api_response :post, 200 do
          assert_equal 10, parsed_body["backupCodes"].size
          assert_empty(parsed_body["backupCodes"] & previous)
        end
      end

      it "refuses while two-factor is off" do
        sign_in data

        assert_api_response :post, 400 do
          assert_equal "otp.not_enabled", parsed_body["code"]
        end
      end
    end
  end
end
