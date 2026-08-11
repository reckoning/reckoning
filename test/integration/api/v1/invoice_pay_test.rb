# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoicePayTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices/{id}/pay" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Mark an invoice paid") do
          operationId "payInvoice"
          tags "Invoices"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Invoice
          end

          response(403, "not payable from this state") do
            schema ::V1::Schemas::Message
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

      it "moves a charged invoice to paid" do
        invoice.charge!

        assert_api_response :put, 200, path_params: {id: invoice.id} do
          assert_equal "paid", parsed_body["state"]
        end
      end

      # created -> paid is not a transition the workflow allows, and the
      # ability refuses it before the model is asked.
      it "refuses to pay an invoice that was never charged" do
        assert_api_response :put, 403, path_params: {id: invoice.id}

        refute invoice.reload.paid?
      end
    end
  end
end
