# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class ExpensesTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses" do
        get("Expenses list") do
          operationId "expenses"
          tags "Expenses"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"
          parameter name: "year", in: :query, required: false, schema: {type: :integer}
          parameter name: "quarter", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 4}
          parameter name: "month", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 12}
          parameter name: "type", in: :query, required: false, schema: {type: :string}
          parameter name: "query", in: :query, required: false,
            description: "Free-text search over description and seller.",
            schema: {type: :string}

          response(200, "successful") do
            schema ::V1::Schemas::Expenses
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Expense") do
          operationId "createExpense"
          tags "Expenses"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::ExpenseInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Expense
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:account) { accounts :enterprise }
      let(:expense) { expenses :two }

      before { account.update!(feature_expenses: true) }

      describe "unauthorized" do
        it "does not list expenses" do
          assert_api_response :get, 401
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the account's expenses" do
          assert_api_response :get, 200 do
            assert_includes parsed_body.map { |item| item["id"] }, expense.id
          end
        end

        # The row prints what the expense actually deducts — not its value —
        # and whether its receipt is there.
        it "reports the deductible value and the receipt state" do
          assert_api_response :get, 200 do
            row = parsed_body.find { |item| item["id"] == expense.id }

            assert_equal expense.usable_value.to_f, row["usableValue"].to_f
            assert_equal false, row["hasReceipt"]
            assert_equal true, row["needsReceipt"]
            assert_nil row["receipt"]
          end
        end

        # A business expense has no receipt to file, so the row must not ask
        # for one.
        it "asks for no receipt on a business expense" do
          business = account.expenses.create!(
            expense_type: "home_office", value: 100, description: "Desk",
            seller: "Daystrom Institute", date: Date.new(Time.zone.now.year, 3, 1),
            vat_percent: 0, private_use_percent: 0, interval: "once"
          )

          assert_api_response :get, 200 do
            row = parsed_body.find { |item| item["id"] == business.id }

            assert_equal false, row["needsReceipt"]
            # The account has entered no office space, so there is no share
            # to deduct — and a decimal zero, which crosses the wire as the
            # string the schema declares, not as a number.
            assert_kind_of String, row["usableValue"]
            assert_equal 0.0, row["usableValue"].to_f
          end
        end

        it "creates an expense" do
          assert_api_response :post, 201, body: {
            expense_type: "other", description: "Tricorder", seller: "Starfleet Supply",
            value: "250.0", date: "2026-08-01", vat_percent: 19, private_use_percent: 0, interval: "once"
          } do
            assert_equal "Tricorder", parsed_body["description"]
            assert_equal "250.0", parsed_body["value"]
          end
        end
      end

      # The whole controller is behind the account feature flag, same as the
      # web UI.
      describe "when the account has expenses switched off" do
        before do
          account.update!(feature_expenses: false)
          sign_in data
        end

        it "is forbidden" do
          assert_api_response :get, 403 do
            assert_equal "feature.disabled", parsed_body["code"]
          end
        end
      end
    end
  end
end
