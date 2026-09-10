# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class BackendStatsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/backend/stats" do
        get("How much there is of everything") do
          operationId "backendStats"
          tags "Backend"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::BackendStats
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:admin) { users :jeanluc }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      it "is forbidden for a non-admin" do
        sign_in users(:data)

        assert_api_response :get, 403
      end

      # Across every account, which is the point of the backend.
      it "counts the users and the accounts" do
        sign_in admin

        assert_api_response :get, 200 do
          assert_equal User.count, parsed_body["usersCount"]
          assert_equal Account.count, parsed_body["accountsCount"]
        end
      end
    end
  end
end
