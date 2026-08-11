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

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"

          response(200, "successful") do
            schema ::V1::Schemas::Customers
            header "Link", schema: {type: :string},
              description: "RFC 8288 pagination links: self, first, prev, next, last."
          end

          response(400, "bad request") do
            schema ::V1::Schemas::StandardError
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

      let(:data) { users :data }
      let(:customer) { customers :starfleet }
      let(:current_account_customer_count) { data.account.customers.count }

      describe "unauthorized" do
        it "does not list customers" do
          assert_api_response :get, 401 do
            assert_equal "unauthorized", parsed_body["code"]
          end
        end

        it "does not create a customer" do
          assert_api_response :post, 401, body: {name: "Vulcan High Command"}
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

        it "describes the page boundaries in the Link header" do
          assert_api_response :get, 200, params: {perPage: 1} do
            assert_equal 1, parsed_body.size

            links = response.headers["Link"]
            assert_includes links, 'rel="self"'
            assert_includes links, 'rel="next"'
            assert_includes links, 'rel="last"'
          end
        end

        it "returns every record when perPage is all" do
          assert_api_response :get, 200, params: {perPage: "all"} do
            assert_equal current_account_customer_count, parsed_body.size
            refute_includes response.headers["Link"].to_s, 'rel="next"'
          end
        end

        it "rejects a page size above the maximum" do
          assert_api_response :get, 400, params: {perPage: 1_000} do
            assert_equal "pagination.max_per_page_reached", parsed_body["code"]
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
      end
    end
  end
end
