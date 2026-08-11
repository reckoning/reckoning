# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoiceSendMailTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices/{id}/send_mail" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Email the invoice to the customer") do
          operationId "sendInvoiceMail"
          tags "Invoices"
          produces "application/json"

          response(200, "queued") do
            schema ::V1::Schemas::Message
          end

          response(400, "customer has no invoice email or template") do
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

      it "queues the mailer when the customer is set up for it" do
        invoice.customer.update!(invoice_email: "billing@star.fleet", email_template: "Rechnung anbei")

        assert_difference "InvoiceMailerWorker.jobs.size", 1 do
          assert_api_response :put, 200, path_params: {id: invoice.id}
        end
      end

      it "refuses when the customer has no invoice email" do
        assert_no_difference "InvoiceMailerWorker.jobs.size" do
          assert_api_response :put, 400, path_params: {id: invoice.id} do
            assert_equal "validation_error.invoice.send", parsed_body["code"]
          end
        end
      end
    end
  end
end
