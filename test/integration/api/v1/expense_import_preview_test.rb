# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpenseImportPreviewTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expense_imports/preview" do
        post("Parse a bank statement into an editable preview") do
          operationId "previewExpenseImport"
          tags "ExpenseImports"
          # The only multipart endpoint in the API — it takes a file.
          consumes "multipart/form-data"
          produces "application/json"

          request_body required: true, content: {
            "multipart/form-data" => {
              schema: ::V1::Schemas::Inputs::ExpenseImportPreviewInput
            }
          }

          response(200, "parsed") do
            schema ::V1::Schemas::ExpenseImportPreview
          end

          response(422, "nothing could be parsed from the file") do
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

      # The DSL validates request bodies as JSON before sending. This body is
      # multipart and carries a file, so that check does not apply — the
      # schema itself stays `string`/`binary`, which is correct for the
      # published contract.
      before do
        @request_validation = OpenapiRuby.configuration.test_request_validation
        OpenapiRuby.configuration.test_request_validation = false
        data.account.update_columns(feature_expenses: true)
      end

      after { OpenapiRuby.configuration.test_request_validation = @request_validation }

      def statement
        fixture_file_upload("adac_credit_card.csv", "text/csv")
      end

      it "is unauthorized when signed out" do
        assert_api_response :post, 401, body: {file: statement}
      end

      describe "signed in" do
        before { sign_in data }

        it "parses the file into rows carrying the chosen defaults" do
          assert_api_response :post, 200, body: {
            file: statement, expense_type: "licenses", vat_percent: "19"
          } do
            refute_empty parsed_body["rows"]
            assert(parsed_body["rows"].all? { |row| row["expenseType"] == "licenses" })
          end
        end

        # Nothing is persisted until the second step.
        it "saves nothing" do
          assert_no_difference "Expense.count" do
            assert_api_response :post, 200, body: {file: statement, expense_type: "licenses"}
          end
        end

        it "is unprocessable when the file yields no rows" do
          empty = Rack::Test::UploadedFile.new(StringIO.new(""), "text/csv", original_filename: "empty.csv")

          assert_api_response :post, 422, body: {file: empty, expense_type: "licenses"} do
            assert_equal "validation_error.expense.import", parsed_body["code"]
          end
        end
      end
    end
  end
end
