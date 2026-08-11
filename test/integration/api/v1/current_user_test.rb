# frozen_string_literal: true

require "openapi_helper"

# Separate class from UsersTest: `assert_api_response` picks the first
# parameterless api_path for a verb, so /users and /users/current can't share
# one.
module Api
  module V1
    class CurrentUserTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/users/current" do
        get("Signed-in user") do
          operationId "currentUser"
          tags "Users"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::User
          end

          response(403, "forbidden") do
            schema ::V1::Schemas::Message
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:admin) { users :jeanluc }
      let(:member) { users :data }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      it "returns the signed-in user" do
        sign_in admin

        assert_api_response :get, 200 do
          assert_equal admin.email, parsed_body["email"]
          assert_equal admin.id, parsed_body["id"]
        end
      end

      # `authorize! :read, User` is admin-only, so a plain member cannot read
      # even their own record here. Worth revisiting when the SPA needs a
      # `/me` endpoint (Phase A3) — this is not that endpoint.
      it "is forbidden for a plain member" do
        sign_in member

        assert_api_response :get, 403
      end
    end
  end
end
