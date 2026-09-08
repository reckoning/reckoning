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
      let(:account) { accounts :enterprise }

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

        # The overtime panel: the hours this week, today, and what each
        # employed customer is ahead or behind by.
        it "reports the hours behind the overtime panel" do
          assert_api_response :get, 200 do
            overtime = parsed_body["overtime"]

            assert overtime.key?("weeklyHours")
            assert overtime.key?("dailyHours")
            assert_kind_of Array, overtime["customers"]
          end
        end

        # `Customer#overtime` answers nil unless the customer is employed and
        # has workdays and weekly hours — those are left out rather than
        # reported as zero, the way the server-rendered panel skips them.
        it "leaves out a customer that has no schedule" do
          assert_api_response :get, 200 do
            names = parsed_body["overtime"]["customers"].map { |entry| entry["name"] }

            assert_not_includes names, customers(:starfleet).name
          end
        end

        it "reports an employed customer's overtime" do
          # `workdays` counts the working days since the employment date, so a
          # schedule is an employment date plus weekly hours.
          customers(:starfleet).update!(
            weekly_hours: 40, employment_date: 30.days.ago.to_date, employment_end_date: nil
          )

          assert_api_response :get, 200 do
            entry = parsed_body["overtime"]["customers"].find { |item| item["name"] == "Starfleet" }

            assert entry, "expected the employed customer in the panel"
            assert entry.key?("hours")
          end
        end

        # Without a provision rate both rows stay out of the summary.
        it "reports no provision for an account without a rate" do
          assert_api_response :get, 200 do
            assert_nil parsed_body["provision"]
            assert_nil parsed_body["lastYearProvision"]
          end
        end

        it "reports the provision once the account carries a rate" do
          account.update!(provision: "10")

          assert_api_response :get, 200 do
            assert_not_nil parsed_body["provision"]
            assert_not_nil parsed_body["lastYearProvision"]
          end
        end

        # Two years, each as a running total and as sums per month — summed
        # here because the client would otherwise need both years' invoices.
        it "reports the chart series" do
          invoice.charge!

          assert_api_response :get, 200 do
            chart = parsed_body["chart"]

            assert_equal 12, chart["labels"].size
            assert_equal 4, chart["datasets"].size
            assert chart["datasets"].all? { |dataset| dataset.key?("color") && dataset.key?("data") }
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
