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

        # The payload was shaped for the AngularJS project service and carried
        # little more than a name. The SPA list and form need what the ERB
        # screens read off the record.
        it "returns what the list and the form need" do
          project.update!(rate: 90, budget: 1000, budget_hours: 20, invoice_addition: "Danke")

          assert_api_response :get, 200, path_params: {id: project.id} do
            assert_equal project.customer_id, parsed_body["customerId"]
            assert_equal "active", parsed_body["workflowState"]
            assert_equal "90.0", parsed_body["rate"]
            assert_equal "1000.0", parsed_body["budget"]
            assert_equal "20.0", parsed_body["budgetHours"]
            assert_equal "Danke", parsed_body["invoiceAddition"]
            assert parsed_body.key?("timerValues")
            assert parsed_body.key?("budgetPercent")
          end
        end

        # Dividing by a budget nobody set is what the ERB guarded before it
        # drew the progress bar.
        it "leaves the budget share empty when there is no budget" do
          project.update!(budget: 0, budget_hours: 0)

          assert_api_response :get, 200, path_params: {id: project.id} do
            assert_nil parsed_body["budgetPercent"]
          end
        end

        # Both were on the ERB form and in no input schema, so the SPA form
        # could not have carried them over.
        it "writes the dates the ERB form had" do
          assert_api_response :patch, 200, path_params: {id: project.id}, body: {
            name: project.name,
            start_date: "2026-01-01T00:00:00Z",
            end_date: "2026-06-30T00:00:00Z"
          }

          assert_equal Date.new(2026, 1, 1), project.reload.start_date.to_date
          assert_equal Date.new(2026, 6, 30), project.reload.end_date.to_date
        end

        it "is not found for a project from another account" do
          assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
        end
      end
    end
  end
end
