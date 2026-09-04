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

      # The account has 2FA on, so the password alone is not enough. Both
      # factors go through the one endpoint the SPA has.
      describe "two-factor" do
        before do
          data.otp_secret = ::User.generate_otp_secret
          data.otp_required_for_login = true
          data.save!
        end

        it "rejects the password on its own" do
          assert_api_response :post, 400, body: {email: data.email, password: password} do
            assert_equal "session.create", parsed_body["code"]
          end
        end

        it "accepts a current totp code" do
          assert_api_response :post, 200, body: {
            email: data.email, password: password, otp_token: data.current_otp
          }
        end

        it "rejects a wrong totp code" do
          assert_api_response :post, 400, body: {
            email: data.email, password: password, otp_token: "000000"
          }
        end

        # The codes the settings screen hands out are the only way back in for
        # someone who lost their authenticator, and /signin takes them in this
        # same field.
        it "accepts a backup code" do
          code = data.generate_otp_backup_codes!.first
          data.save!

          assert_api_response :post, 200, body: {
            email: data.email, password: password, otp_token: code
          }
        end

        it "consumes the backup code it accepted" do
          code = data.generate_otp_backup_codes!.first
          data.save!

          assert_api_response :post, 200, body: {
            email: data.email, password: password, otp_token: code
          }

          assert_api_response :post, 400, body: {
            email: data.email, password: password, otp_token: code
          }
        end
      end

      # Lockable is live (`lock_strategy = :failed_attempts`,
      # `unlock_strategy = :email`), and the counter has to move on this
      # endpoint too or the SPA login is a way around the lock.
      describe "lockable" do
        it "counts a wrong password toward the lock" do
          assert_api_response :post, 400, body: {email: data.email, password: "wrong"}

          assert_equal 1, data.reload.failed_attempts
        end

        it "locks the account once the attempts run out" do
          data.update!(failed_attempts: ::User.maximum_attempts - 1)

          assert_api_response :post, 400, body: {email: data.email, password: "wrong"}

          assert data.reload.access_locked?
        end

        it "mails the unlock instructions when it locks" do
          data.update!(failed_attempts: ::User.maximum_attempts - 1)

          assert_emails 1 do
            assert_api_response :post, 400, body: {email: data.email, password: "wrong"}
          end
        end

        it "refuses a locked account holding the right password" do
          data.lock_access!(send_instructions: false)

          assert_api_response :post, 400, body: {email: data.email, password: password} do
            assert_equal "session.create", parsed_body["code"]
          end
        end

        it "clears the counter after a successful sign-in" do
          data.update!(failed_attempts: 3)

          assert_api_response :post, 200, body: {email: data.email, password: password}

          assert_equal 0, data.reload.failed_attempts
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
