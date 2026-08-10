# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class TimersTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/timers" do
        get("Timers list") do
          operationId "timers"
          tags "Timers"
          produces "application/json"

          parameter name: "date", in: :query, required: false,
            schema: {type: :string, format: :date}
          parameter name: "startDate", in: :query, required: false,
            description: "Combined with endDate to filter a range.",
            schema: {type: :string, format: :date}
          parameter name: "endDate", in: :query, required: false,
            schema: {type: :string, format: :date}
          parameter name: "projectId", in: :query, required: false,
            schema: {type: :string, format: :uuid}
          parameter name: "uninvoiced", in: :query, required: false,
            description: "Present and non-blank restricts to uninvoiced timers.",
            schema: {type: :string}
          parameter name: "billable", in: :query, required: false, schema: {type: :string}
          parameter name: "running", in: :query, required: false, schema: {type: :string}
          parameter name: "limit", in: :query, required: false, schema: {type: :integer, minimum: 1}

          response(200, "successful") do
            schema ::V1::Schemas::Timers
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Timer") do
          operationId "createTimer"
          tags "Timers"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::TimerInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Timer
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

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

      describe "unauthorized" do
        it "does not list timers" do
          assert_api_response :get, 401
        end

        it "does not create a timer" do
          assert_api_response :post, 401, body: {task_id: task.id, value: "1.0"}
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the user's timers" do
          assert_api_response :get, 200 do
            assert_includes parsed_body.map { |item| item["id"] }, timer.id
          end
        end

        it "filters by date" do
          assert_api_response :get, 200, params: {date: timer.date.to_s} do
            dates = parsed_body.map { |item| item["date"] }.uniq

            assert_equal [timer.date.to_s], dates
          end
        end

        it "creates a timer on a task" do
          assert_api_response :post, 201, body: {task_id: task.id, date: "2026-08-10", value: "1.5"} do
            assert_equal task.id, parsed_body["taskId"]
            # Decimals cross the wire as strings.
            assert_equal "1.5", parsed_body["value"]
          end
        end

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
end
