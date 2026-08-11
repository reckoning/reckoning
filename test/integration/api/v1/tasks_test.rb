# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class TasksTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/tasks" do
        get("Tasks list") do
          operationId "tasks"
          tags "Tasks"
          produces "application/json"

          parameter name: "weekDate", in: :query, required: false,
            description: "Any date in a week. Restricts the nested timers to " \
                         "that week and to the signed-in user.",
            schema: {type: :string, format: :date}

          response(200, "successful") do
            schema ::V1::Schemas::Tasks
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Task") do
          operationId "createTask"
          tags "Tasks"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::TaskInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Task
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:project) { projects :narendra3 }
      let(:task) { tasks :away_mission }

      describe "unauthorized" do
        it "does not list tasks" do
          assert_api_response :get, 401
        end

        it "does not create a task" do
          assert_api_response :post, 401, body: {name: "Diplomacy", project_id: project.id}
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the account's tasks with their timers" do
          assert_api_response :get, 200 do
            listed = parsed_body.find { |item| item["id"] == task.id }

            assert listed, "expected #{task.name} in the list"
            assert_equal project.id, listed["projectId"]
            assert_kind_of Array, listed["timers"]
          end
        end

        it "creates a task on a project" do
          assert_api_response :post, 201, body: {name: "Diplomacy", project_id: project.id} do
            assert_equal "Diplomacy", parsed_body["name"]
            assert_equal project.id, parsed_body["projectId"]
          end
        end

        it "rejects a task without a name" do
          assert_api_response :post, 400, body: {name: "", project_id: project.id} do
            assert_equal "validation_error.task.create", parsed_body["code"]
          end
        end
      end
    end
  end
end
