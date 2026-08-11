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

        it "creates an expense" do
          assert_api_response :post, 201, body: {
            expense_type: "other", description: "Tricorder", seller: "Starfleet Supply",
            value: "250.0", date: "2026-08-01", vat_percent: 19, private_use_percent: 0, interval: "once"
          } do
            assert_equal "Tricorder", parsed_body["description"]
            assert_equal "250.0", parsed_body["value"]
          end
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
  end
end
