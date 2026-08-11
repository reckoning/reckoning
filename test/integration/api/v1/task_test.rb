# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class TaskTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/tasks/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        patch("Update Task") do
          operationId "updateTask"
          tags "Tasks"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::TaskUpdateInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Task
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

        delete("Destroy Task") do
          operationId "destroyTask"
          tags "Tasks"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "has timers") do
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
      let(:task) { tasks :away_mission }

      before { sign_in data }

      it "updates a task" do
        assert_api_response :patch, 200, path_params: {id: task.id}, body: {name: "Diplomacy", billable: false} do
          assert_equal "Diplomacy", parsed_body["name"]
          refute parsed_body["billable"]
        end
      end

      # Deleting a task would take its timers with it, so tracked work has
      # to be moved or removed first.
      it "refuses to destroy a task that has timers" do
        assert task.timers.exists?

        assert_api_response :delete, 400, path_params: {id: task.id} do
          assert_equal "validation_error.task.destroy_failure_dependency", parsed_body["code"]
        end

        assert Task.exists?(task.id)
      end

      it "destroys a task with no timers" do
        empty = project.tasks.create!(name: "Unused")

        assert_api_response :delete, 200, path_params: {id: empty.id}

        assert_nil Task.find_by(id: empty.id)
      end

      it "is not found for a task from another account" do
        assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
      end
    end
  end
end
