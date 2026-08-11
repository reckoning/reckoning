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

      # The flow the SPA uses: log in for a cookie, then call a protected
      # endpoint with no Authorization header at all.
      describe "cookie session" do
        it "establishes a session the browser can reuse" do
          assert_api_response :post, 200, body: {email: data.email, password: password}

          get "/api/v1/me", headers: {"Accept" => "application/json"}

          assert_response :ok
          assert_equal data.id, JSON.parse(response.body)["id"]
        end

        # The login form's "Angemeldet bleiben" checkbox. Without this the SPA
        # cannot offer it at all, since the session cookie dies with the browser.
        #
        # `config.rememberable_options` sets `secure: true`, and Rails declines
        # to write a secure cookie over plain HTTP — so the request has to be
        # SSL for the cookie to appear at all.
        it "issues a remember cookie when asked" do
          https!

          assert_api_response :post, 200, body: {
            email: data.email, password: password, remember_me: true
          }

          assert cookies[:remember_user_token].present?
          assert data.reload.remember_created_at.present?
        end

        it "issues no remember cookie by default" do
          https!

          assert_api_response :post, 200, body: {email: data.email, password: password}

          assert cookies[:remember_user_token].blank?
          assert_nil data.reload.remember_created_at
        end

        it "clears the session on destroy" do
          assert_api_response :post, 200, body: {email: data.email, password: password}
          delete "/api/v1/sessions", headers: {"Accept" => "application/json"}

          assert_response :ok

          get "/api/v1/me", headers: {"Accept" => "application/json"}

          assert_response :unauthorized
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
