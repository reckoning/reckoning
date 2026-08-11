# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class TimerTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/timers/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Update Timer") do
          operationId "updateTimer"
          tags "Timers"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::TimerInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Timer
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

        delete("Destroy Timer") do
          operationId "destroyTimer"
          tags "Timers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Timer
          end

          response(400, "already invoiced") do
            schema ::V1::Schemas::Message
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
      let(:task) { tasks :away_mission }
      let(:timer) { timers :twohours }

      before { sign_in data }

      it "updates a timer" do
        assert_api_response :put, 200, path_params: {id: timer.id},
          body: {task_id: task.id, value: "3.25", note: "Diplomatic incident"} do
          assert_equal "3.25", parsed_body["value"]
          assert_equal "Diplomatic incident", parsed_body["note"]
        end
      end

      it "destroys a timer that is not on an invoice" do
        assert_api_response :delete, 200, path_params: {id: timer.id}

        assert_nil Timer.find_by(id: timer.id)
      end

      it "is not found for another user's timer" do
        assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
      end
    end
  end
end
