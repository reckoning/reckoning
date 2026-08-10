# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ProjectsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/projects" do
        get("Projects list") do
          operationId "projects"
          tags "Projects"
          produces "application/json"

          parameter name: "state", in: :query, required: false,
            description: "Workflow state to filter by. Defaults to active.",
            schema: {type: :string}
          parameter name: "sort", in: :query, required: false,
            description: "\"used\" orders by most recently tracked.",
            schema: {type: :string, enum: %w[used]}
          parameter name: "withoutIds", in: :query, required: false,
            description: "Project ids to exclude.",
            schema: {type: :array, items: {type: :string, format: :uuid}}

          response(200, "successful") do
            schema ::V1::Schemas::Projects
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      api_path "/projects/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

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

      api_path "/projects/{id}/archive" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Archive Project") do
          operationId "archiveProject"
          tags "Projects"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "already archived") do
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
        it "does not list projects" do
          assert_api_response :get, 401
        end

        it "does not destroy a project" do
          assert_api_response :delete, 401, path_params: {id: project.id}

          assert Project.exists?(project.id)
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists active projects with their tasks" do
          assert_api_response :get, 200 do
            listed = parsed_body.find { |item| item["id"] == project.id }

            assert listed, "expected #{project.name} in the list"
            assert_kind_of Array, listed["tasks"]
          end
        end

        it "excludes ids passed in withoutIds" do
          assert_api_response :get, 200, params: {withoutIds: [project.id]} do
            refute_includes parsed_body.map { |item| item["id"] }, project.id
          end
        end

        it "is not found for a project from another account" do
          assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
        end

        it "archives a project" do
          assert_api_response :put, 200, path_params: {id: project.id}

          assert project.reload.archived?
        end

        it "refuses to archive twice" do
          project.archive!
          project.save

          assert_api_response :put, 400, path_params: {id: project.id} do
            assert_equal "validation_error.project.archive", parsed_body["code"]
          end
        end
      end
    end
  end
end
