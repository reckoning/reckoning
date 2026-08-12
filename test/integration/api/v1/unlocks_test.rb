# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class UnlocksTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/unlocks" do
        post("Resend the unlock email") do
          operationId "requestUnlock"
          tags "Unlocks"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::UnlockRequestInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end
        end

        put("Unlock an account using a token") do
          operationId "unlockAccount"
          tags "Unlocks"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::UnlockInput}
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

      describe "requesting an unlock email" do
        it "sends one for a locked account" do
          data.lock_access!

          assert_difference "ActionMailer::Base.deliveries.size", 1 do
            assert_api_response :post, 200, body: {email: data.email}
          end
        end

        # config.paranoid is on: an unauthenticated caller must not be able to
        # tell a registered address from an unregistered one.
        it "reports the same result for an unknown address" do
          assert_api_response :post, 200, body: {email: "nobody@star.fleet"} do
            refute_includes parsed_body["message"], "Translation missing"
          end
        end
      end

      describe "unlocking with a token" do
        # Only the digest is stored, so the raw token has to come from the call
        # that generates it — `send_unlock_instructions` returns it.
        it "unlocks the account" do
          data.lock_access!(send_instructions: false)
          raw = data.send_unlock_instructions

          assert data.reload.access_locked?

          assert_api_response :put, 200, body: {unlock_token: raw} do
            refute_includes parsed_body["message"], "Translation missing"
          end

          refute data.reload.access_locked?
        end

        it "refuses an invalid token" do
          data.lock_access!(send_instructions: false)

          assert_api_response :put, 400, body: {unlock_token: "not-a-real-token"} do
            assert_equal "validation_error.unlock.update", parsed_body["code"]
            refute_includes parsed_body["message"], "Translation missing"
          end

          assert data.reload.access_locked?
        end
      end
    end
  end
end
