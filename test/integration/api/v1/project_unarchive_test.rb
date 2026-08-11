# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ProjectUnarchiveTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/projects/{id}/unarchive" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Unarchive Project") do
          operationId "unarchiveProject"
          tags "Projects"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "not archived") do
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

      before { sign_in data }

      it "unarchives an archived project" do
        project.archive!
        project.save

        assert_api_response :put, 200, path_params: {id: project.id}

        refute project.reload.archived?
      end

      it "refuses to unarchive an active project" do
        assert_api_response :put, 400, path_params: {id: project.id} do
          assert_equal "validation_error.project.unarchive", parsed_body["code"]
        end
      end
    end
  end
end
