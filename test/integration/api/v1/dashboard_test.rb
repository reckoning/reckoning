# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class DashboardTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/dashboard" do
        get("Totals for the home screen") do
          operationId "dashboard"
          tags "Dashboard"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Dashboard
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:invoice) { invoices :january }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      describe "signed in" do
        before { sign_in data }

        it "returns the account's totals for the current year" do
          assert_api_response :get, 200 do
            assert_equal Time.zone.now.year, parsed_body["year"]
            assert parsed_body.key?("uninvoicedAmount")
            assert_kind_of Integer, parsed_body["openInvoicesCount"]
          end
        end

        it "counts invoices still in the created state as open" do
          assert_api_response :get, 200 do
            assert_operator parsed_body["openInvoicesCount"], :>=, 1
          end

          invoice.charge!

          assert_api_response :get, 200 do
            assert_equal 0, parsed_body["openInvoicesCount"]
          end
        end

        # `value` is derived by a before_save hook from the positions, so the
        # expectation has to come from the model rather than a literal.
        it "moves a charged invoice's value into the charged total" do
          InvoicePosition.create!(invoicable: invoice, description: "Work", hours: 5, rate: 100)
          invoice.save!
          invoice.charge!

          expected = data.account.invoices.charged.sum(:value)
          assert_operator expected, :>, 0, "fixture setup should produce a non-zero charged invoice"

          assert_api_response :get, 200 do
            assert_equal expected.to_f, parsed_body["chargedSum"].to_f
          end
        end

        # The february fixture belongs to the defiant account.
        it "is scoped to the caller's account" do
          other = invoices(:february)
          InvoicePosition.create!(invoicable: other, description: "Work", hours: 9, rate: 100)
          other.save!
          other.charge!

          assert_api_response :get, 200 do
            assert_equal 0.0, parsed_body["chargedSum"].to_f,
              "another account's charged invoice leaked into the totals"
          end
        end
      end
    end
  end
end
