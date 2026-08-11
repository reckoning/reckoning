# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpenseBulkDestroyTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses/bulk_destroy" do
        post("Destroy many expenses") do
          operationId "bulkDestroyExpenses"
          tags "Expenses"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ExpenseBulkDestroyInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::BulkResult
          end

          response(400, "nothing selected to destroy") do
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

      describe "signed in" do
        before { sign_in data }

        it "destroys the selected expenses" do
          assert_api_response :post, 200, body: {expenseIds: [expense.id]} do
            assert_equal 1, parsed_body["count"]
          end

          assert_nil Expense.find_by(id: expense.id)
        end

        it "reports a real message rather than a missing translation" do
          assert_api_response :post, 200, body: {expenseIds: [expense.id]} do
            refute_includes parsed_body["message"], "Translation missing"
          end
        end

        it "refuses when nothing is selected" do
          assert_api_response :post, 400, body: {expenseIds: []} do
            assert_equal "validation_error.expense.bulk_destroy", parsed_body["code"]
            refute_includes parsed_body["message"], "Translation missing"
          end
        end

        # The ids are scoped to the signed-in account, so another account's
        # expense is simply not found rather than destroyed.
        it "ignores an expense from another account" do
          foreign = accounts(:defiant).expenses.create!(
            expense_type: "gwg", value: 9.99, description: "Cloaking device",
            seller: "Tal Shiar", date: Date.new(2026, 8, 1)
          )

          assert_api_response :post, 400, body: {expenseIds: [foreign.id]}

          assert Expense.exists?(foreign.id)
        end
      end

      it "is unauthorized when signed out" do
        assert_api_response :post, 401, body: {expenseIds: [expense.id]}

        assert Expense.exists?(expense.id)
      end

      describe "when the account has expenses switched off" do
        before do
          account.update!(feature_expenses: false)
          sign_in data
        end

        it "is forbidden" do
          assert_api_response :post, 403, body: {expenseIds: [expense.id]} do
            assert_equal "feature.disabled", parsed_body["code"]
          end
        end
      end
    end
  end
end
