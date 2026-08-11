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
      end
    end
  end
end
