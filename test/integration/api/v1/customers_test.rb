# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class CustomersTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/customers" do
        get("Customers list") do
          operationId "customers"
          tags "Customers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Customers
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Customer") do
          operationId "createCustomer"
          tags "Customers"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::CustomerInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Customer
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

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
        it "does not list customers" do
          assert_api_response :get, 401 do
            assert_equal "unauthorized", parsed_body["code"]
          end
        end

        it "does not show a customer" do
          assert_api_response :get, 401, path_params: {id: customer.id}
        end

        it "does not create a customer" do
          assert_api_response :post, 401, body: {name: "Vulcan High Command"}
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

        it "lists customers" do
          assert_api_response :get, 200 do
            assert_includes parsed_body.map { |item| item["name"] }, customer.name
          end
        end

        it "shows a customer" do
          assert_api_response :get, 200, path_params: {id: customer.id} do
            assert_equal customer.id, parsed_body["id"]
            assert_equal customer.name, parsed_body["name"]
          end
        end

        it "creates a customer" do
          assert_api_response :post, 201, body: {name: "Vulcan High Command", email: "t.pol@vulcan.gov"} do
            assert_equal "Vulcan High Command", parsed_body["name"]
            assert_equal "t.pol@vulcan.gov", parsed_body["email"]
          end
        end

        it "rejects a customer without a name" do
          assert_api_response :post, 400, body: {name: ""} do
            assert_equal "validation_error.customer.create", parsed_body["code"]
            assert_includes parsed_body["errors"].keys, "name"
          end
        end

        it "rejects a customer whose email the model refuses" do
          assert_api_response :post, 400, body: {name: "Vulcan High Command", email: "not-an-email"} do
            assert_equal "validation_error.customer.create", parsed_body["code"]
            assert_includes parsed_body["errors"].keys, "email"
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
