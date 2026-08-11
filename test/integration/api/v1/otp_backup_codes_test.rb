# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
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
