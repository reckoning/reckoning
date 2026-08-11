# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
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
  end
end
