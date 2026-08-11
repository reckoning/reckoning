# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ProjectTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/projects/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get Project") do
          operationId "project"
          tags "Projects"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Project
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update Project") do
          operationId "updateProject"
          tags "Projects"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ProjectInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Project
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Destroy Project") do
          operationId "destroyProject"
          tags "Projects"
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

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:project) { projects :narendra3 }

      describe "unauthorized" do
        it "does not destroy a project" do
          assert_api_response :delete, 401, path_params: {id: project.id}

          assert Project.exists?(project.id)
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "shows a project" do
          assert_api_response :get, 200, path_params: {id: project.id} do
            assert_equal project.id, parsed_body["id"]
          end
        end

        it "updates a project" do
          assert_api_response :patch, 200, path_params: {id: project.id}, body: {name: "Narendra III"} do
            assert_equal "Narendra III", parsed_body["name"]
          end

          assert_equal "Narendra III", project.reload.name
        end

        it "is not found for a project from another account" do
          assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
        end
      end
    end
  end
end
