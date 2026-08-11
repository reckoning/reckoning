# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ConfigTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/config" do
        get("Settings the SPA needs before sign-in") do
          operationId "appConfig"
          tags "Config"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::AppConfig
          end
        end
      end

      # Read before anyone is signed in, so it must not require a session.
      it "is readable when signed out" do
        assert_api_response :get, 200 do
          refute_nil parsed_body["registrationEnabled"]
        end
      end

      it "reports whether signup is offered" do
        assert_api_response :get, 200 do
          assert_equal Rails.configuration.app.registration, parsed_body["registrationEnabled"]
        end
      end

      # Without a resolvable subdomain there is no account to name, and the
      # login has nothing to brand itself with.
      it "has no account name off a subdomain" do
        assert_api_response :get, 200 do
          assert_nil parsed_body["accountName"]
        end
      end
    end
  end
end
