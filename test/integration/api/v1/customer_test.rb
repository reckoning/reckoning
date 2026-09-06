# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class CustomerTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/customers/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get Customer") do
          operationId "customer"
          tags "Customers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Customer
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update Customer") do
          operationId "updateCustomer"
          tags "Customers"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::CustomerInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Customer
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

        delete("Destroy Customer") do
          operationId "destroyCustomer"
          tags "Customers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::StandardError
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
      let(:customer) { customers :starfleet }

      describe "unauthorized" do
        it "does not show a customer" do
          assert_api_response :get, 401, path_params: {id: customer.id}
        end

        it "does not destroy a customer" do
          assert_api_response :delete, 401, path_params: {id: customer.id}

          assert_equal customer, Customer.find_by(id: customer.id)
        end
      end

      describe "signed in" do
        before do
          sign_in data
        end

        it "shows a customer" do
          assert_api_response :get, 200, path_params: {id: customer.id} do
            assert_equal customer.id, parsed_body["id"]
            assert_equal customer.name, parsed_body["name"]
          end
        end

        it "updates a customer" do
          assert_api_response :patch, 200, path_params: {id: customer.id},
            body: {name: "Starfleet Command", country: "US"} do
            assert_equal "Starfleet Command", parsed_body["name"]
            assert_equal "US", parsed_body["country"]
          end

          assert_equal "Starfleet Command", customer.reload.name
        end

        # The ERB form could empty these by submitting a blank field, which
        # Rails cast to nil. The SPA has to send null to do the same — and a
        # payment period of 0 is not an empty one, it makes invoices due
        # immediately.
        it "clears a number when sent null" do
          customer.update!(payment_due: 14, weekly_hours: 40)

          assert_api_response :patch, 200, path_params: {id: customer.id},
            body: {name: customer.name, paymentDue: nil, weeklyHours: nil}

          assert_nil customer.reload.payment_due
          assert_nil customer.reload.weekly_hours
        end

        it "rejects an update that clears the name" do
          assert_api_response :patch, 400, path_params: {id: customer.id}, body: {name: ""} do
            assert_equal "validation_error.customer.update", parsed_body["code"]
            refute_includes parsed_body["message"], "Translation missing"
          end
        end

        it "destroys a customer without invoices" do
          klingon = customers :klingon

          assert_api_response :delete, 200, path_params: {id: klingon.id}

          assert_nil Customer.find_by(id: klingon.id)
        end

        it "does not find a customer from another account" do
          assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
        end
      end
    end
  end
end
