# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    # Its own class because the receipt is a file: it travels multipart, on
    # its own path, rather than inside the expense's json.
    class ExpenseReceiptTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses/{id}/receipt" do
        parameter name: "id", in: :path, required: true, schema: {type: :string, format: :uuid}

        put("Attach a receipt to an expense") do
          operationId "updateExpenseReceipt"
          tags "Expenses"
          consumes "multipart/form-data"
          produces "application/json"

          request_body required: true, content: {
            "multipart/form-data" => {schema: ::V1::Schemas::Inputs::ExpenseReceiptInput}
          }

          response(200, "attached") do
            schema ::V1::Schemas::Expense
          end

          response(400, "no file, or one of a type the receipt does not take") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Take the receipt off an expense") do
          operationId "destroyExpenseReceipt"
          tags "Expenses"
          produces "application/json"

          response(200, "removed") do
            schema ::V1::Schemas::Expense
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
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

      # The DSL validates request bodies as JSON before sending. This one is
      # multipart and carries a file, so that check does not apply — the
      # schema itself stays `string`/`binary`, which is the published
      # contract.
      before do
        @request_validation = OpenapiRuby.configuration.test_request_validation
        OpenapiRuby.configuration.test_request_validation = false
        account.update!(feature_expenses: true)
      end

      after { OpenapiRuby.configuration.test_request_validation = @request_validation }

      def receipt(name = "receipt.pdf", type = "application/pdf")
        fixture_file_upload(name, type)
      end

      it "is unauthorized when signed out" do
        assert_api_response :put, 401, params: {id: expense.id}, body: {receipt: receipt}
      end

      describe "when the account has expenses switched off" do
        before do
          account.update!(feature_expenses: false)
          sign_in data
        end

        it "is forbidden either way" do
          assert_api_response :put, 403, params: {id: expense.id}, body: {receipt: receipt} do
            assert_equal "feature.disabled", parsed_body["code"]
          end

          assert_api_response :delete, 403, params: {id: expense.id}
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "attaches the file and reports it on the expense" do
          assert_api_response :put, 200, params: {id: expense.id}, body: {receipt: receipt} do
            assert_equal true, parsed_body["hasReceipt"]
            assert_equal "receipt.pdf", parsed_body["receipt"]["filename"]
            assert_equal "application/pdf", parsed_body["receipt"]["contentType"]
            assert_includes parsed_body["receipt"]["url"], "/rails/active_storage/"
          end

          assert expense.reload.receipt.attached?
        end

        it "takes an image of one as well" do
          assert_api_response :put, 200, params: {id: expense.id},
            body: {receipt: receipt("receipt.png", "image/png")} do
            assert_equal "image/png", parsed_body["receipt"]["contentType"]
          end
        end

        it "replaces a receipt that is already there" do
          expense.receipt.attach(receipt)

          assert_api_response :put, 200, params: {id: expense.id},
            body: {receipt: receipt("receipt.png", "image/png")} do
            assert_equal "receipt.png", parsed_body["receipt"]["filename"]
          end

          assert_equal 1, expense.reload.receipt.attachments.size
        end

        it "is a bad request without a file" do
          assert_api_response :put, 400, params: {id: expense.id}, body: {} do
            assert_equal "validation_error.expense.receipt", parsed_body["code"]
          end
        end

        # A receipt is a pdf or a picture of one.
        it "refuses a file of another type and keeps none of it" do
          assert_api_response :put, 400, params: {id: expense.id},
            body: {receipt: receipt("adac_credit_card.csv", "text/csv")} do
            assert_equal "validation_error.expense.receipt", parsed_body["code"]
          end

          assert_not expense.reload.receipt.attached?
        end

        # The type that counts is the one the file is stored under, which is
        # what the model's validator compares — not what the upload claimed.
        it "refuses a file whose contents are not what it says" do
          mislabelled = Rack::Test::UploadedFile.new(
            Rails.root.join("test/fixtures/files/adac_credit_card.csv"), "application/octet-stream",
            original_filename: "receipt.csv"
          )

          assert_api_response :put, 400, params: {id: expense.id}, body: {receipt: mislabelled}

          assert_not expense.reload.receipt.attached?
        end

        # Nothing of a refused upload is left behind, either on the expense
        # or in storage.
        it "keeps no blob of a refused upload" do
          assert_no_difference "ActiveStorage::Blob.count" do
            assert_api_response :put, 400, params: {id: expense.id},
              body: {receipt: receipt("adac_credit_card.csv", "text/csv")}
          end
        end

        # Attaching to a saved record writes at once and pushes the previous
        # receipt out, so the upload has to be turned away before that — or a
        # rejected file takes a good receipt with it.
        it "leaves the receipt that is already there alone" do
          expense.receipt.attach(receipt)

          assert_api_response :put, 400, params: {id: expense.id},
            body: {receipt: receipt("adac_credit_card.csv", "text/csv")}

          expense.reload

          assert expense.receipt.attached?
          assert_equal "receipt.pdf", expense.receipt.filename.to_s
        end

        it "removes the receipt again" do
          expense.receipt.attach(receipt)

          assert_api_response :delete, 200, params: {id: expense.id} do
            assert_equal false, parsed_body["hasReceipt"]
            assert_nil parsed_body["receipt"]
          end

          assert_not expense.reload.receipt.attached?
        end

        it "is not found for another account's expense" do
          other = accounts(:defiant).expenses.create!(
            expense_type: "gwg", value: 10, description: "Cloak", seller: "Tal Shiar",
            date: Date.new(2026, 3, 1), vat_percent: 0, private_use_percent: 0, interval: "once"
          )

          assert_api_response :put, 404, params: {id: other.id}, body: {receipt: receipt}
          assert_api_response :delete, 404, params: {id: other.id}
        end
      end
    end
  end
end
