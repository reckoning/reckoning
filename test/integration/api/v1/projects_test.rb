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

        post("Create new Project") do
          operationId "createProject"
          tags "Projects"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ProjectInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Project
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "customer belongs to another account") do
            schema ::V1::Schemas::Message
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

        it "creates a project with nested tasks" do
          assert_api_response :post, 201, body: {
            name: "Deep Space 9",
            customer_id: customers(:starfleet).id,
            rate: "120.0",
            tasks_attributes: [{name: "Station repairs"}]
          } do
            assert_equal "Deep Space 9", parsed_body["name"]
            assert_equal ["Station repairs"], parsed_body["tasks"].map { |t| t["name"] }
          end
        end

        it "rejects a project without a name" do
          assert_api_response :post, 400, body: {name: "", customer_id: customers(:starfleet).id} do
            assert_equal "validation_error.project.create", parsed_body["code"]
            refute_includes parsed_body["message"], "Translation missing"
          end
        end

        # Authorization runs through the customer's account, so a project
        # pointed at another account's customer is refused outright.
        it "refuses a project under another account's customer" do
          assert_no_difference "Project.count" do
            assert_api_response :post, 403, body: {name: "Infiltration", customer_id: customers(:defiant_customer).id}
          end
        end
      end
    end
  end
end
