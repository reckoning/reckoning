# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class SessionsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/sessions" do
        post("Exchange credentials for a token") do
          operationId "createSession"
          tags "Sessions"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::SessionInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Session
          end

          response(400, "invalid credentials") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Revoke the current token") do
          operationId "destroySession"
          tags "Sessions"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:password) { "enterprise" }

      describe "create" do
        it "returns a token for valid credentials" do
          assert_api_response :post, 200, body: {email: data.email, password: password} do
            assert parsed_body["auth_token"].present?

            payload = JsonWebToken.decode(parsed_body["auth_token"])
            assert_equal data.id, payload[:user_id]
          end
        end

        it "rejects a wrong password" do
          assert_api_response :post, 400, body: {email: data.email, password: "wrong"} do
            assert_equal "session.create", parsed_body["code"]
          end
        end

        it "rejects an unknown email" do
          assert_api_response :post, 400, body: {email: "nobody@star.fleet", password: password} do
            assert_equal "session.create", parsed_body["code"]
          end
        end
      end

      describe "destroy" do
        it "is unauthorized without a token" do
          assert_api_response :delete, 401
        end

        it "revokes the token it was called with" do
          auth_token = AuthToken.create!(user_id: data.id)
          jwt = JsonWebToken.encode(auth_token.to_jwt_payload)

          assert_api_response :delete, 200, headers: {"Authorization" => "Bearer #{jwt}"} do
            assert_equal "sessions.destroy", parsed_body["code"]
          end

          assert_nil AuthToken.find_by(id: auth_token.id)
        end
      end
    end
  end
end
