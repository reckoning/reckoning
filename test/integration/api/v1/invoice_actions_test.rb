# frozen_string_literal: true

require "openapi_helper"

# One class per action: charge, pay and send_mail are all PUT on a path with
# an id, and assert_api_response resolves a verb to the first match.
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
