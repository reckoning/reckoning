# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class MeTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me" do
        get("Signed-in user's own record") do
          operationId "me"
          tags "Me"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::CurrentUser
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update the signed-in user's profile") do
          operationId "updateMe"
          tags "Me"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::MeInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::CurrentUser
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

      describe "unauthorized" do
        it "does not return a profile" do
          assert_api_response :get, 401
        end

        it "does not update a profile" do
          assert_api_response :patch, 401, body: {name: "Lore"}
        end
      end

      describe "signed in" do
        before { sign_in data }

        # Unlike /users/current, which authorizes against the User class and so
        # is admin-only, this reads the caller's own record.
        it "returns the caller's own record" do
          assert_api_response :get, 200 do
            assert_equal data.id, parsed_body["id"]
            assert_equal data.email, parsed_body["email"]
            assert_equal data.account_id, parsed_body["accountId"]
          end
        end

        it "updates the profile without touching the password" do
          previous_digest = data.encrypted_password

          assert_api_response :patch, 200, body: {name: "Data Soong", layout: "top"} do
            assert_equal "Data Soong", parsed_body["name"]
            assert_equal "top", parsed_body["layout"]
          end

          assert_equal previous_digest, data.reload.encrypted_password
        end

        it "rejects an invalid email" do
          assert_api_response :patch, 400, body: {email: "not-an-email"} do
            assert_equal "validation_error.user.update", parsed_body["code"]
            assert_includes parsed_body["errors"].keys, "email"
          end
        end

        it "ignores fields outside the input schema" do
          assert_api_response :patch, 200, body: {name: "Data Soong"} do
            refute parsed_body["admin"], "admin must not be settable through /me"
          end

          refute data.reload.admin
        end
      end
    end
  end
end
