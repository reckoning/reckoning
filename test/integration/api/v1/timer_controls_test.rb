# frozen_string_literal: true

require "openapi_helper"

# Separate classes from TimersTest: `assert_api_response` picks the first
# api_path whose template has a path param, so /timers/{id},
# /timers/{id}/start and /timers/{id}/stop cannot share one class.
module Api
  module V1
    class TimerStartTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/timers/{id}/start" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Start Timer") do
          operationId "startTimer"
          tags "Timers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Timer
          end

          response(400, "bad request") do
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
      let(:timer) { timers :twohours }

      it "is unauthorized when signed out" do
        assert_api_response :put, 401, path_params: {id: timer.id}
      end

      it "starts a stopped timer" do
        sign_in data

        assert_api_response :put, 200, path_params: {id: timer.id} do
          assert parsed_body["started"]
          assert parsed_body["startedAt"]
        end
      end
    end

    class TimerStopTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/timers/{id}/stop" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Stop Timer") do
          operationId "stopTimer"
          tags "Timers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Timer
          end

          response(400, "bad request") do
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
      let(:timer) { timers :twohours }

      it "is unauthorized when signed out" do
        assert_api_response :put, 401, path_params: {id: timer.id}
      end

      it "stops a running timer" do
        sign_in data
        timer.start

        assert_api_response :put, 200, path_params: {id: timer.id} do
          refute parsed_body["started"]
        end
      end
    end
  end
end
