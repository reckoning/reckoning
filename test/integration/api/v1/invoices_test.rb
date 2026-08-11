# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoicesTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices" do
        get("Invoices list") do
          operationId "invoices"
          tags "Invoices"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"
          parameter name: "state", in: :query, required: false,
            schema: {type: :string, enum: %w[created charged paid]}
          parameter name: "year", in: :query, required: false, schema: {type: :integer}
          parameter name: "quarter", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 4}
          parameter name: "month", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 12}
          parameter name: "paid_in_year", in: :query, required: false, schema: {type: :integer}
          parameter name: "paid_in_quarter", in: :query, required: false, schema: {type: :integer}
          parameter name: "paid_in_month", in: :query, required: false, schema: {type: :integer}

          response(200, "successful") do
            schema ::V1::Schemas::Invoices
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Invoice") do
          operationId "createInvoice"
          tags "Invoices"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::InvoiceInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Invoice
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:invoice) { invoices :january }
      let(:project) { projects :narendra3 }

      describe "unauthorized" do
        it "does not list invoices" do
          assert_api_response :get, 401
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the account's invoices with their positions" do
          assert_api_response :get, 200 do
            listed = parsed_body.find { |item| item["id"] == invoice.id }

            assert listed, "expected invoice #{invoice.ref} in the list"
            assert_kind_of Array, listed["positions"]
          end
        end

        # The february fixture belongs to the defiant account.
        it "does not leak another account's invoices" do
          assert_api_response :get, 200 do
            refute_includes parsed_body.map { |item| item["id"] }, invoices(:february).id
          end
        end

        it "filters by state" do
          assert_api_response :get, 200, params: {state: "paid"} do
            refute_includes parsed_body.map { |item| item["id"] }, invoice.id
          end
        end

        it "creates an invoice with positions" do
          assert_api_response :post, 201, body: {
            project_id: project.id,
            date: "2026-08-01",
            positions_attributes: [{description: "Consulting", hours: "10.0", rate: "100.0"}]
          } do
            assert_equal 1, parsed_body["positions"].size
            # value is derived from hours x rate.
            assert_equal "1000.0", parsed_body["value"]
          end
        end
      end
    end
  end
end
