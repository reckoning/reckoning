# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class BackendUsersTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/backend/users" do
        get("Users across every account") do
          operationId "backendUsers"
          tags "Backend"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"

          parameter name: "sort", in: :query, required: false,
            schema: {type: :string, enum: %w[id email admin current_sign_in_at created_at]},
            description: "The columns the backend list sorts by. Anything else is the newest first."
          parameter name: "direction", in: :query, required: false,
            schema: {type: :string, enum: %w[asc desc]}

          response(200, "successful") do
            schema ::V1::Schemas::BackendUsers
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create a user") do
          operationId "createBackendUser"
          tags "Backend"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::BackendUserInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::BackendUser
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
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
      let(:member) { users :data }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      it "is forbidden for a non-admin" do
        sign_in member

        assert_api_response :get, 403 do
          assert_equal "forbidden", parsed_body["code"]
        end
      end

      describe "as an admin" do
        before { sign_in admin }

        # Unlike /users, this spans accounts.
        it "lists users from every account" do
          assert_api_response :get, 200, params: {perPage: "all"} do
            emails = parsed_body.map { |user| user["email"] }

            assert_includes emails, member.email
            assert_includes emails, users(:worf).email
          end
        end

        # The admin never picks the password: a random one is set and the user
        # is mailed a confirmation to choose their own.
        it "creates a user without a password" do
          assert_difference "User.count", 1 do
            assert_api_response :post, 201, body: {
              email: "barclay@star.fleet", name: "Reginald Barclay", account_id: admin.account_id
            } do
              refute parsed_body["confirmed"]
            end
          end
        end

        # The server-rendered list sorted by five columns; the endpoint takes
        # the same set and falls back to the newest first.
        it "sorts by the columns the list offers" do
          assert_api_response :get, 200, params: {sort: "email", direction: "asc", perPage: "all"} do
            emails = parsed_body.map { |user| user["email"] }

            assert_equal emails.sort, emails
          end
        end

        it "says when a user was last seen" do
          member.update_columns(current_sign_in_at: Time.zone.parse("2026-03-04T10:00:00Z"))

          assert_api_response :get, 200, params: {perPage: "all"} do
            user = parsed_body.find { |entry| entry["id"] == member.id }

            assert_equal member.reload.current_sign_in_at, Time.zone.parse(user["currentSignInAt"])
          end
        end

        it "rejects a duplicate email" do
          assert_no_difference "User.count" do
            assert_api_response :post, 400, body: {email: member.email, account_id: admin.account_id} do
              assert_equal "validation_error.user.create", parsed_body["code"]
            end
          end
        end
      end
    end
  end
end
