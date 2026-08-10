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

      api_path "/backend/users/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get a user") do
          operationId "backendUser"
          tags "Backend"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::BackendUser
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update a user") do
          operationId "updateBackendUser"
          tags "Backend"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::BackendUserInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::BackendUser
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Destroy a user") do
          operationId "destroyBackendUser"
          tags "Backend"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
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

        it "shows a user" do
          assert_api_response :get, 200, path_params: {id: member.id} do
            assert_equal member.email, parsed_body["email"]
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

        it "rejects a duplicate email" do
          assert_no_difference "User.count" do
            assert_api_response :post, 400, body: {email: member.email, account_id: admin.account_id} do
              assert_equal "validation_error.user.create", parsed_body["code"]
            end
          end
        end

        it "updates a user" do
          assert_api_response :patch, 200, path_params: {id: member.id}, body: {enabled: false} do
            refute parsed_body["enabled"]
          end

          refute member.reload.enabled
        end

        it "destroys a user" do
          assert_api_response :delete, 200, path_params: {id: users(:will).id}

          assert_nil User.find_by(id: users(:will).id)
        end

        it "is not found for an unknown id" do
          assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
        end
      end
    end
  end
end
