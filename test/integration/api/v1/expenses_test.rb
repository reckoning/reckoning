# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpensesTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses" do
        get("Expenses list") do
          operationId "expenses"
          tags "Expenses"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"
          parameter name: "year", in: :query, required: false, schema: {type: :integer}
          parameter name: "quarter", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 4}
          parameter name: "month", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 12}
          parameter name: "type", in: :query, required: false, schema: {type: :string}
          parameter name: "query", in: :query, required: false,
            description: "Free-text search over description and seller.",
            schema: {type: :string}

          response(200, "successful") do
            schema ::V1::Schemas::Expenses
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Expense") do
          operationId "createExpense"
          tags "Expenses"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ExpenseInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Expense
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

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

      before { account.update!(feature_expenses: true) }

      describe "unauthorized" do
        it "does not list expenses" do
          assert_api_response :get, 401
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the account's expenses" do
          assert_api_response :get, 200 do
            assert_includes parsed_body.map { |item| item["id"] }, expense.id
          end
        end

        it "shows an expense" do
          assert_api_response :get, 200, path_params: {id: expense.id} do
            assert_equal expense.id, parsed_body["id"]
          end
        end

        it "creates an expense" do
          assert_api_response :post, 201, body: {
            expense_type: "other", description: "Tricorder", seller: "Starfleet Supply",
            value: "250.0", date: "2026-08-01", vat_percent: 19, private_use_percent: 0, interval: "once"
          } do
            assert_equal "Tricorder", parsed_body["description"]
            assert_equal "250.0", parsed_body["value"]
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

      # The whole controller is behind the account feature flag, same as the
      # web UI.
      describe "when the account has expenses switched off" do
        before do
          account.update!(feature_expenses: false)
          sign_in data
        end

        it "is forbidden" do
          assert_api_response :get, 403 do
            assert_equal "feature.disabled", parsed_body["code"]
          end
        end
      end
    end

    class ExpenseBulkTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses/bulk_update" do
        post("Apply the same attributes to many expenses") do
          operationId "bulkUpdateExpenses"
          tags "Expenses"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ExpenseBulkInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::BulkResult
          end

          response(400, "nothing selected to change") do
            schema ::V1::Schemas::ValidationError
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

      it "applies attributes to the selected expenses" do
        assert_api_response :post, 200, body: {expenseIds: [expense.id], vat_percent: 7} do
          assert_equal 1, parsed_body["count"]
        end

        assert_equal 7, expense.reload.vat_percent
      end

      # Blank fields are skipped, so a partly filled bulk bar leaves the rest
      # of each record alone.
      it "ignores blank attributes" do
        previous_type = expense.expense_type

        assert_api_response :post, 200, body: {expenseIds: [expense.id], expense_type: nil, vat_percent: 7}

        assert_equal previous_type, expense.reload.expense_type
      end

      it "refuses when nothing is selected" do
        assert_api_response :post, 400, body: {expenseIds: [], vat_percent: 7} do
          assert_equal "validation_error.expense.bulk_update", parsed_body["code"]
        end
      end

      it "refuses when no attributes are given" do
        assert_api_response :post, 400, body: {expenseIds: [expense.id]} do
          assert_equal "validation_error.expense.bulk_update", parsed_body["code"]
        end
      end
    end
  end
end
