# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    # Its own class because the DSL matches requests on verb and path params,
    # which cannot tell `GET /expenses` and `GET /expenses/summary` apart.
    class ExpenseSummaryTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/expenses/summary" do
        get("What the filtered expenses add up to") do
          operationId "expenseSummary"
          tags "Expenses"
          produces "application/json"

          parameter name: "year", in: :query, required: false, schema: {type: :integer}
          parameter name: "quarter", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 4}
          parameter name: "month", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 12}
          parameter name: "type", in: :query, required: false, schema: {type: :string}
          parameter name: "query", in: :query, required: false,
            description: "Free-text search over the description.",
            schema: {type: :string}

          response(200, "successful") do
            schema ::V1::Schemas::ExpenseSummary
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
      let(:year) { Time.zone.now.year }

      before { account.update!(feature_expenses: true) }

      def expense_worth(value, type: "gwg", date: nil, **attributes)
        account.expenses.create!(
          {
            expense_type: type, value: value, description: "Tricorder",
            seller: "Daystrom Institute", date: date || Date.new(year, 3, 1),
            vat_percent: 0, private_use_percent: 0, interval: "once"
          }.merge(attributes)
        )
      end

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

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

      describe "signed in" do
        before do
          sign_in data
          account.expenses.destroy_all
        end

        it "adds up what the account may deduct" do
          expense_worth(100)
          expense_worth(250)

          assert_api_response :get, 200 do
            assert_equal 2, parsed_body["count"]
            assert_equal 350.0, parsed_body["value"].to_f
          end
        end

        # `private_use_percent` is the share that is not the business's, and
        # only the rest is deductible.
        it "leaves the private share out of the total" do
          expense_worth(100, private_use_percent: 40)

          assert_api_response :get, 200 do
            assert_equal 60.0, parsed_body["value"].to_f
          end
        end

        it "reports the vat of the set beside it" do
          expense_worth(100, vat_percent: 19)

          assert_api_response :get, 200 do
            assert_equal 19.0, parsed_body["vat"].to_f
          end
        end

        # The numbers have to belong to the set the list is showing, not to
        # everything — otherwise the total under a filtered table is a lie.
        it "counts only what the filter leaves" do
          expense_worth(100, date: Date.new(year, 3, 1))
          expense_worth(900, date: Date.new(year - 1, 3, 1))

          assert_api_response :get, 200, params: {year: year} do
            assert_equal 1, parsed_body["count"]
            assert_equal 100.0, parsed_body["value"].to_f
          end
        end

        # An expense on an interval stands for one entry per period it
        # covers: a year of a monthly 10 is 120, not 10.
        it "counts an interval once per period it covers" do
          expense_worth(
            10, date: nil, interval: "monthly",
            started_at: Date.new(year, 1, 1), ended_at: Date.new(year, 12, 31)
          )

          assert_api_response :get, 200, params: {year: year} do
            assert_equal 120.0, parsed_body["value"].to_f
          end
        end

        # An AfA expense deducts one year's write-off rather than its value,
        # and that share does not repeat per period either.
        it "counts an afa expense at its yearly write-off" do
          expense_worth(1200, type: "afa", afa_type: afa_types(:three_years))

          assert_api_response :get, 200 do
            assert_equal 400.0, parsed_body["value"].to_f
          end
        end

        # Health and social insurance are not business expenses. The panel
        # that reports them counts them separately, so they stay out of this
        # total unless they are what you asked to see.
        it "leaves insurances out until they are the filter" do
          expense_worth(100)
          expense_worth(500, type: "insurances")

          assert_api_response :get, 200 do
            assert_equal 100.0, parsed_body["value"].to_f
          end

          assert_api_response :get, 200, params: {type: "insurances"} do
            assert_equal 500.0, parsed_body["value"].to_f
          end
        end

        # The year dropdown needs the years you could switch to, so this one
        # ignores the filters on purpose.
        it "offers the years the expenses reach back to" do
          expense_worth(100, date: Date.new(year - 2, 7, 1))

          assert_api_response :get, 200, params: {year: year} do
            assert_equal [year, year - 1, year - 2], parsed_body["years"].first(3)
          end
        end

        it "offers last year and this one for an account without expenses" do
          assert_api_response :get, 200 do
            assert_equal 0, parsed_body["count"]
            assert_equal [year, year - 1], parsed_body["years"]
          end
        end

        it "leaves another account's expenses out" do
          accounts(:defiant).expenses.create!(
            expense_type: "gwg", value: 999, description: "Cloaking device",
            seller: "Tal Shiar", date: Date.new(year, 3, 1),
            vat_percent: 0, private_use_percent: 0, interval: "once"
          )
          expense_worth(100)

          assert_api_response :get, 200 do
            assert_equal 1, parsed_body["count"]
            assert_equal 100.0, parsed_body["value"].to_f
          end
        end
      end
    end
  end
end
