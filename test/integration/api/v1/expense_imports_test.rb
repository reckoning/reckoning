# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpenseImportsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expense_imports" do
        post("Persist the rows kept from a preview") do
          operationId "createExpenseImport"
          tags "ExpenseImports"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ExpenseImportInput}
          }

          response(201, "imported") do
            schema ::V1::Schemas::BulkResult
          end

          response(422, "nothing selected, or a row failed validation") do
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

      def row(overrides = {})
        {
          include: "1",
          date: "2026-03-04",
          value: "42.50",
          vat_percent: "19",
          private_use_percent: "0",
          interval: "once",
          seller: "Daystrom Institute",
          description: "Positronic spares",
          expense_type: "licenses"
        }.merge(overrides)
      end

      before { data.account.update_columns(feature_expenses: true) }

      it "is unauthorized when signed out" do
        assert_api_response :post, 401, body: {rows: [row]}
      end

      describe "signed in" do
        before { sign_in data }

        it "creates an expense per kept row" do
          assert_difference "Expense.count", 2 do
            assert_api_response :post, 201, body: {rows: [row, row(seller: "Utopia Planitia")]} do
              assert_equal 2, parsed_body["count"]
            end
          end
        end

        # The checkbox column drives this: rows without `include` are dropped.
        it "ignores rows that were not selected" do
          assert_difference "Expense.count", 1 do
            assert_api_response :post, 201, body: {rows: [row, row(include: "0", seller: "Skipped")]}
          end

          assert_nil Expense.find_by(seller: "Skipped")
        end

        it "is unprocessable when nothing was selected" do
          assert_no_difference "Expense.count" do
            assert_api_response :post, 422, body: {rows: [row(include: "0")]} do
              assert_equal "validation_error.expense.import", parsed_body["code"]
            end
          end
        end

        # All or nothing: one invalid row fails the whole import rather than
        # leaving a partial one behind.
        it "saves nothing when a row is invalid" do
          assert_no_difference "Expense.count" do
            assert_api_response :post, 422, body: {rows: [row, row(seller: "", description: "")]}
          end
        end
      end

      describe "when the account has expenses switched off" do
        before do
          data.account.update_columns(feature_expenses: false)
          sign_in data
        end

        it "is forbidden" do
          assert_api_response :post, 403, body: {rows: [row]}
        end
      end
    end
  end
end
