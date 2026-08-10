# frozen_string_literal: true

require "openapi_helper"

# Own class: /me and /me/password are both parameterless, and
# `assert_api_response` resolves a verb to the first matching api_path.
module Api
  module V1
    class MePasswordTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/me/password" do
        patch("Change the signed-in user's password") do
          operationId "updateMyPassword"
          tags "Me"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::PasswordChangeInput}
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
      let(:current_password) { "enterprise" }

      it "is unauthorized when signed out" do
        assert_api_response :patch, 401, body: {
          current_password: current_password, password: "new-warp-core-2026"
        }
      end

      describe "signed in" do
        before { sign_in data }

        it "changes the password when the current one is right" do
          assert_api_response :patch, 200, body: {
            current_password: current_password,
            password: "new-warp-core-2026",
            password_confirmation: "new-warp-core-2026"
          }

          assert data.reload.valid_password?("new-warp-core-2026")
        end

        it "keeps the session alive afterwards" do
          assert_api_response :patch, 200, body: {
            current_password: current_password,
            password: "new-warp-core-2026",
            password_confirmation: "new-warp-core-2026"
          }

          get "/api/v1/me", headers: {"Accept" => "application/json"}

          assert_response :ok
        end

        it "rejects a wrong current password" do
          assert_api_response :patch, 400, body: {
            current_password: "not-my-password",
            password: "new-warp-core-2026",
            password_confirmation: "new-warp-core-2026"
          } do
            assert_includes parsed_body["errors"].keys, "current_password"
          end

          refute data.reload.valid_password?("new-warp-core-2026")
        end

        it "rejects a mismatched confirmation" do
          assert_api_response :patch, 400, body: {
            current_password: current_password,
            password: "new-warp-core-2026",
            password_confirmation: "something-else"
          }

          refute data.reload.valid_password?("new-warp-core-2026")
        end
      end
    end
  end
end
