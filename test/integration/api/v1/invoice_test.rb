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

      # A client cannot derive these: the state machine decides charge and pay,
      # and an expired trial reads everything while writing nothing. Guessing
      # means offering buttons the endpoint answers with 403.
      it "says what this user may do with this invoice" do
        assert_api_response :get, 200, path_params: {id: invoice.id} do
          abilities = parsed_body["abilities"]

          assert_equal true, abilities["charge"], "a created invoice can be charged"
          assert_equal false, abilities["pay"], "a created invoice cannot be paid"
          assert_equal true, abilities["update"]
        end
      end

      it "closes the actions when the trial has run out" do
        accounts(:enterprise).update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)

        assert_api_response :get, 200, path_params: {id: invoice.id} do
          abilities = parsed_body["abilities"]

          assert_equal false, abilities["charge"]
          assert_equal false, abilities["update"]
          assert_equal false, abilities["destroy"]
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
