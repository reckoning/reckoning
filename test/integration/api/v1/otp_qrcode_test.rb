# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
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
  end
end
