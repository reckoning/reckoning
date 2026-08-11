# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoiceChargeTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices/{id}/charge" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        put("Charge an invoice") do
          operationId "chargeInvoice"
          tags "Invoices"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Invoice
          end

          response(403, "not chargeable from this state") do
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

      it "is unauthorized when signed out" do
        assert_api_response :put, 401, path_params: {id: invoice.id}
      end

      it "moves a created invoice to charged" do
        sign_in data

        assert_api_response :put, 200, path_params: {id: invoice.id} do
          assert_equal "charged", parsed_body["state"]
          refute parsed_body["editable"], "a charged invoice is no longer editable"
        end
      end

      # The state machine lives in the ability: `can :charge` only holds while
      # the invoice is in `created`, so a repeat charge is refused as
      # forbidden rather than as a failed transition.
      it "refuses to charge an invoice that is already charged" do
        invoice.charge!
        sign_in data

        assert_api_response :put, 403, path_params: {id: invoice.id}

        assert_equal "charged", invoice.reload.current_state.to_s
      end
    end
  end
end
