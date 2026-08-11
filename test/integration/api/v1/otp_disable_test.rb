# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
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
  end
end
