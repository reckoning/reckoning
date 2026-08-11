# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoiceTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get Invoice") do
          operationId "invoice"
          tags "Invoices"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Invoice
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update Invoice") do
          operationId "updateInvoice"
          tags "Invoices"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::InvoiceInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Invoice
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Destroy Invoice") do
          operationId "destroyInvoice"
          tags "Invoices"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "bad request") do
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

      it "shows an invoice" do
        assert_api_response :get, 200, path_params: {id: invoice.id} do
          assert_equal invoice.id, parsed_body["id"]
          assert_equal "created", parsed_body["state"]
        end
      end

      it "is not found for another account's invoice" do
        assert_api_response :get, 404, path_params: {id: invoices(:february).id}
      end

      it "updates an invoice" do
        assert_api_response :patch, 200, path_params: {id: invoice.id}, body: {date: "2026-09-09"} do
          assert_equal "2026-09-09", parsed_body["date"]
        end
      end

      it "destroys an invoice" do
        assert_api_response :delete, 200, path_params: {id: invoice.id}

        assert_nil Invoice.find_by(id: invoice.id)
      end
    end
  end
end
