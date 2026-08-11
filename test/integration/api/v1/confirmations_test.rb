# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ConfirmationsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/confirmations" do
        post("Resend the confirmation email") do
          operationId "requestConfirmation"
          tags "Confirmations"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ConfirmationRequestInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end
        end

        put("Confirm an email address using a token") do
          operationId "confirmEmail"
          tags "Confirmations"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ConfirmationInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "invalid or expired token") do
            schema ::V1::Schemas::ValidationError
          end
        end
      end

      let(:unconfirmed) do
        User.create!(
          account: accounts(:enterprise),
          name: "Reginald Barclay",
          email: "barclay@star.fleet",
          password: "enterprise",
          password_confirmation: "enterprise"
        )
      end

      describe "requesting a confirmation email" do
        it "sends one for an unconfirmed address" do
          unconfirmed

          assert_difference "ActionMailer::Base.deliveries.size", 1 do
            assert_api_response :post, 200, body: {email: unconfirmed.email}
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

      describe "confirming with a token" do
        it "confirms the address" do
          raw = unconfirmed.confirmation_token

          assert_api_response :put, 200, body: {confirmation_token: raw} do
            refute_includes parsed_body["message"], "Translation missing"
          end

          assert unconfirmed.reload.confirmed?
        end

        it "refuses an invalid token" do
          unconfirmed

          assert_api_response :put, 400, body: {confirmation_token: "not-a-real-token"} do
            assert_equal "validation_error.confirmation.update", parsed_body["code"]
            refute_includes parsed_body["message"], "Translation missing"
          end

          refute unconfirmed.reload.confirmed?
        end
      end
    end
  end
end
