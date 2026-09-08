# frozen_string_literal: true

require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "should calulate list of dates based on interval setting" do
    expense = expenses(:one)
    expense.interval = :monthly
    expense.started_at = Date.new(2022, 1, 31)
    expense.ended_at = Date.new(2022, 6, 1)
    expense.save

    assert_equal %w[
      2022-01-31 2022-02-28 2022-03-31 2022-04-30 2022-05-31
    ], expense.dates_for_interval.map(&:iso8601)
  end

  describe "a home office expense" do
    let(:account) { accounts :enterprise }
    let(:expense) do
      account.expenses.create!(
        expense_type: "home_office", value: 100, description: "Desk",
        seller: "Daystrom Institute", date: Date.new(2026, 3, 1),
        vat_percent: 19, private_use_percent: 0, interval: "once"
      )
    end

    it "deducts the share of the office the account may deduct" do
      account.update!(office_space: 100, deductible_office_space: 20)

      assert_equal 20.0, expense.usable_value
      assert_in_delta 3.8, expense.vat_value, 0.01
    end

    # The account has entered no office space, so the share is unknown. It
    # used to answer nil, and every sum over it — and the vat beside it —
    # raised on the multiplication.
    it "deducts nothing while the account has no office to go by" do
      account.update!(office_space: nil, deductible_office_space: nil, deductible_office_percent: nil)

      assert_equal 0.0, expense.usable_value
      assert_equal 0.0, expense.vat_value
    end
  end
end
