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

        it "shows an invoice" do
          assert_api_response :get, 200, path_params: {id: invoice.id} do
            assert_equal invoice.id, parsed_body["id"]
            assert_equal "created", parsed_body["state"]
          end
        end

        it "is not found for another account's invoice" do
          assert_api_response :get, 404, path_params: {id: invoices(:february).id}
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
end
