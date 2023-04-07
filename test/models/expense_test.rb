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
end
