# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpenseImportColumnsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expense_imports/columns" do
        get("The columns an imported CSV may carry") do
          operationId "expenseImportColumns"
          tags "ExpenseImports"
          produces "application/json"

          response(200, "the columns") do
            schema ::V1::Schemas::ExpenseImportColumns
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

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      describe "signed in" do
        before do
          data.account.update_columns(feature_expenses: true)
          sign_in data
        end

        it "names the columns the model takes, with their types" do
          assert_api_response :get, 200 do
            names = parsed_body["columns"].map { |column| column["name"] }

            assert_includes names, "id"
            assert_includes names, "value"
            assert_includes names, "expense_type"
            # Derived readers are not columns, so they are not offered.
            refute_includes names, "usable_value"
            assert_equal "uuid", parsed_body["columns"].find { |column| column["name"] == "id" }["type"]
          end
        end
      end

      describe "without the feature" do
        before do
          data.account.update_columns(feature_expenses: false)
          sign_in data
        end

        it "is forbidden" do
          assert_api_response :get, 403
        end
      end
    end
  end
end
