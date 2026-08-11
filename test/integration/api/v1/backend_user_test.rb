# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class BackendUserTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

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

      describe "as an admin" do
        before { sign_in admin }

        it "shows a user" do
          assert_api_response :get, 200, path_params: {id: member.id} do
            assert_equal member.email, parsed_body["email"]
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
