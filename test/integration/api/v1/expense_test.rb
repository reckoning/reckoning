# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpenseTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get Expense") do
          operationId "expense"
          tags "Expenses"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Expense
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update Expense") do
          operationId "updateExpense"
          tags "Expenses"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ExpenseInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Expense
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

        delete("Destroy Expense") do
          operationId "destroyExpense"
          tags "Expenses"
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
      let(:account) { accounts :enterprise }
      let(:expense) { expenses :two }

      before do
        account.update!(feature_expenses: true)
        sign_in data
      end

      it "shows an expense" do
        assert_api_response :get, 200, path_params: {id: expense.id} do
          assert_equal expense.id, parsed_body["id"]
        end
      end

      it "updates an expense" do
        assert_api_response :patch, 200, path_params: {id: expense.id}, body: {description: "Replicator parts"} do
          assert_equal "Replicator parts", parsed_body["description"]
        end
      end

      it "destroys an expense" do
        assert_api_response :delete, 200, path_params: {id: expense.id}

        assert_nil Expense.find_by(id: expense.id)
      end
    end
  end
end
