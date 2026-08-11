# frozen_string_literal: true

require "openapi_helper"

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
  end
end
