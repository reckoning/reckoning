# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class BackendAccountsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/backend/accounts" do
        get("Every account") do
          operationId "backendAccounts"
          tags "Backend"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"

          response(200, "successful") do
            schema ::V1::Schemas::BackendAccounts
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create an account, with the user it cannot exist without") do
          operationId "createBackendAccount"
          tags "Backend"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::BackendAccountCreateInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::BackendAccount
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

        it "lists every account, newest first, with what the list shows" do
          assert_api_response :get, 200, params: {perPage: "all"} do
            names = parsed_body.map { |account| account["name"] }

            assert_includes names, accounts(:enterprise).name
            assert_operator parsed_body.first["usersCount"], :>=, 1
          end
        end

        # The account is invalid without a user, so the first one comes with
        # it — and is mailed a confirmation to pick their own password.
        it "creates an account together with its first user" do
          assert_difference ["Account.count", "User.count"], 1 do
            assert_api_response :post, 201, body: {name: "Vulcan Science Academy", email: "spock@vulcan.gov"} do
              assert_equal "free", parsed_body["plan"]
              assert_equal 1, parsed_body["usersCount"]
            end
          end

          assert User.find_by(email: "spock@vulcan.gov").created_via_admin
        end

        # The schema asks for an address; an empty one gets as far as the
        # model, which will not have an account without a user either.
        it "refuses an account whose user has no address" do
          assert_no_difference "Account.count" do
            assert_api_response :post, 400, body: {name: "Nowhere", email: ""} do
              assert_equal "validation_error.account.create", parsed_body["code"]
            end
          end
        end
      end
    end
  end
end
