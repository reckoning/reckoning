# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class AccountTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/account" do
        get("The signed-in user's account") do
          operationId "account"
          tags "Account"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Account
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update account settings") do
          operationId "updateAccount"
          tags "Account"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::AccountInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Account
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:account) { accounts :enterprise }

      describe "unauthorized" do
        it "does not return the account" do
          assert_api_response :get, 401
        end

        it "does not update the account" do
          assert_api_response :patch, 401, body: {name: "Borg Collective"}

          refute_equal "Borg Collective", account.reload.name
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "returns the caller's own account" do
          assert_api_response :get, 200 do
            assert_equal account.id, parsed_body["id"]
            assert_equal account.name, parsed_body["name"]
          end
        end

        it "updates plain and hstore-backed settings together" do
          assert_api_response :patch, 200, body: {name: "Starfleet HQ", iban: "DE89370400440532013000", country: "DE"} do
            assert_equal "Starfleet HQ", parsed_body["name"]
            assert_equal "DE89370400440532013000", parsed_body["iban"]
            assert_equal "DE", parsed_body["country"]
          end

          account.reload
          assert_equal "Starfleet HQ", account.name
          assert_equal "DE89370400440532013000", account.iban
        end

        # These messages are user-facing, and a missing key surfaces as
        # "Translation missing" rather than failing anything.
        it "returns a translated message when validation fails" do
          assert_api_response :patch, 400, body: {name: ""} do
            assert_equal "validation_error.account.update", parsed_body["code"]
            refute_includes parsed_body["message"], "Translation missing"
          end
        end

        # `plan` is not in the input schema — billing goes through Stripe.
        it "ignores fields outside the input schema" do
          previous_plan = account.plan

          assert_api_response :patch, 200, body: {name: "Starfleet HQ"}

          assert_equal previous_plan, account.reload.plan
        end
      end
    end
  end
end
