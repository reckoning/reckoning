# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    # Its own class because the DSL matches requests on verb and path params,
    # which cannot tell `GET /invoices` and `GET /invoices/summary` apart.
    class InvoiceSummaryTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices/summary" do
        get("What the filtered invoices add up to") do
          operationId "invoiceSummary"
          tags "Invoices"
          produces "application/json"

          parameter name: "state", in: :query, required: false,
            schema: {type: :string, enum: %w[created charged paid]}
          parameter name: "year", in: :query, required: false, schema: {type: :integer}
          parameter name: "quarter", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 4}
          parameter name: "month", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 12}
          parameter name: "paid_in_year", in: :query, required: false, schema: {type: :integer}
          parameter name: "paid_in_quarter", in: :query, required: false, schema: {type: :integer}
          parameter name: "paid_in_month", in: :query, required: false, schema: {type: :integer}

          response(200, "successful") do
            schema ::V1::Schemas::InvoiceSummary
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:account) { accounts :enterprise }

      # `before_save :set_value` recomputes the column from the invoice's
      # positions, so a value assigned on create is thrown away. These tests
      # are about the summing, not about where a single invoice's value comes
      # from, so they write it past the callback.
      def invoice_worth(value, date: Date.new(2026, 3, 1), ref: nil)
        invoice = account.invoices.create!(
          customer: customers(:starfleet), project: projects(:narendra3), date: date,
          ref: ref || account.invoices.maximum(:ref).to_i + 1
        )
        invoice.update_columns(value: value)
        invoice
      end

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      describe "signed in" do
        before do
          sign_in data
          account.invoices.destroy_all
        end

        it "adds up the account's invoices" do
          invoice_worth(100)
          invoice_worth(250)

          assert_api_response :get, 200 do
            assert_equal 2, parsed_body["count"]
            assert_equal "350.0", parsed_body["value"]
            assert parsed_body.key?("vat")
          end
        end

        # The numbers have to belong to the set the list is showing, not to
        # everything — otherwise the total under a filtered table is a lie.
        it "counts only what the filter leaves" do
          invoice_worth(100, date: Date.new(2026, 3, 1))
          invoice_worth(900, date: Date.new(2025, 3, 1))

          assert_api_response :get, 200, params: {year: 2026} do
            assert_equal 1, parsed_body["count"]
            assert_equal "100.0", parsed_body["value"]
          end
        end

        # The year dropdown needs the years you could switch to, so this one
        # ignores the filters on purpose.
        it "offers every year the account has invoices in" do
          invoice_worth(100, date: Date.new(2026, 3, 1))
          invoice_worth(900, date: Date.new(2024, 7, 1))

          assert_api_response :get, 200, params: {year: 2026} do
            assert_equal 1, parsed_body["count"]
            assert_equal [2026, 2024], parsed_body["years"]
          end
        end

        # Both year dropdowns are fed from this list, and `paid_in_year`
        # filters on `pay_date` — an invoice dated in 2025 and paid in 2026
        # has to make 2026 selectable.
        it "offers the years invoices were paid in too" do
          paid = invoice_worth(100, date: Date.new(2025, 12, 1))
          paid.update_columns(pay_date: Date.new(2026, 1, 15))

          assert_api_response :get, 200 do
            assert_includes parsed_body["years"], 2026
            assert_includes parsed_body["years"], 2025
          end
        end

        # The february fixture belongs to the defiant account.
        it "leaves another account's invoices out" do
          invoice_worth(100)

          assert_api_response :get, 200 do
            assert_equal 1, parsed_body["count"]
            assert_equal "100.0", parsed_body["value"]
          end
        end
      end
    end
  end
end
