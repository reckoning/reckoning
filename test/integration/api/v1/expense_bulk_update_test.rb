# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpenseBulkUpdateTest < ActionDispatch::IntegrationTest
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
