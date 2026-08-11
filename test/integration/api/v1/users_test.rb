# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class UsersTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/users" do
        get("Users list") do
          operationId "users"
          tags "Users"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Users
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

      describe "unauthorized" do
        it "does not list users" do
          assert_api_response :get, 401
        end
      end

      describe "as an admin" do
        before { sign_in admin }

        it "lists the account's users" do
          assert_api_response :get, 200 do
            emails = parsed_body.map { |user| user["email"] }

            assert_includes emails, member.email
            refute_includes emails, users(:worf).email, "users from another account leaked"
          end
        end
      end

      # `authorize! :index, User` is admin-only.
      describe "as a plain member" do
        before { sign_in member }

        it "is forbidden" do
          assert_api_response :get, 403
        end
      end
    end
  end
end
