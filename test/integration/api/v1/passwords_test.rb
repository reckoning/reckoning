# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class PasswordsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/passwords" do
        post("Request a password reset email") do
          operationId "requestPasswordReset"
          tags "Passwords"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::PasswordResetRequestInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end
        end

        put("Set a new password using a reset token") do
          operationId "resetPassword"
          tags "Passwords"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::PasswordResetInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "invalid or expired token") do
            schema ::V1::Schemas::ValidationError
          end
        end
      end

      let(:data) { users :data }

      describe "requesting a reset" do
        it "sends an email for a known address" do
          assert_emails 1 do
            assert_api_response :post, 200, body: {email: data.email}
          end

          assert data.reload.reset_password_token.present?
        end

        # Reporting "no such account" would let anyone enumerate addresses.
        it "reports success for an unknown address without sending anything" do
          assert_no_emails do
            assert_api_response :post, 200, body: {email: "nobody@star.fleet"}
          end
        end
      end

      describe "setting a new password" do
        it "accepts a valid token" do
          token = data.send_reset_password_instructions

          assert_api_response :put, 200, body: {
            reset_password_token: token,
            password: "new-warp-core-2026",
            password_confirmation: "new-warp-core-2026"
          }

          assert data.reload.valid_password?("new-warp-core-2026")
        end

        it "rejects an unknown token" do
          assert_api_response :put, 400, body: {
            reset_password_token: "not-a-real-token",
            password: "new-warp-core-2026",
            password_confirmation: "new-warp-core-2026"
          } do
            assert_equal "validation_error.password.update", parsed_body["code"]
          end

          refute data.reload.valid_password?("new-warp-core-2026")
        end

        it "rejects a mismatched confirmation" do
          token = data.send_reset_password_instructions

          assert_api_response :put, 400, body: {
            reset_password_token: token,
            password: "new-warp-core-2026",
            password_confirmation: "something-else"
          }

          refute data.reload.valid_password?("new-warp-core-2026")
        end
      end
    end
  end
end
