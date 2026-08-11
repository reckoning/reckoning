# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoiceSendTestMailTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices/{id}/send_test_mail" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        post("Email a preview of the invoice") do
          operationId "sendInvoiceTestMail"
          tags "Invoices"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::TestMailInput}
          }

          response(200, "queued") do
            schema ::V1::Schemas::Message
          end

          response(400, "invalid address") do
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
      let(:invoice) { invoices :january }

      before { sign_in data }

      it "queues a preview to the given address" do
        assert_difference "InvoiceTestMailerWorker.jobs.size", 1 do
          assert_api_response :post, 200, path_params: {id: invoice.id},
            body: {email: "picard@star.fleet"}
        end
      end

      it "rejects an invalid address" do
        assert_no_difference "InvoiceTestMailerWorker.jobs.size" do
          assert_api_response :post, 400, path_params: {id: invoice.id},
            body: {email: "not-an-email"} do
            assert_equal "validation_error.invoice.send_test_mail", parsed_body["code"]
          end
        end
      end
    end
  end
end
