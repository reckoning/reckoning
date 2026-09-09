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

    # Decimals cross the wire as strings, floats as numbers, and the API
    # declares these fields as strings.
    it "answers a decimal either way" do
      assert_kind_of BigDecimal, expense.usable_value

      account.update!(office_space: nil, deductible_office_space: nil, deductible_office_percent: nil)

      assert_kind_of BigDecimal, expense.usable_value
    end
  end

  # `CSV.generate` takes keywords: the hash was passed positionally, so it
  # became the string to write into and raised a TypeError on Ruby 3.4 —
  # which is a 500 on the export, not a broken column.
  describe "the csv export" do
    let(:account) { accounts :enterprise }

    it "writes a header and a row for every expense" do
      csv = account.expenses.to_csv

      assert_includes csv.lines.first, "description"
      assert_equal account.expenses.count + 1, csv.lines.size
    end

    it "takes the options csv takes" do
      assert_includes account.expenses.to_csv(col_sep: ";").lines.first, "description;"
    end
  end

  describe "an afa expense" do
    let(:account) { accounts :enterprise }

    def afa(**attributes)
      account.expenses.new({
        expense_type: "afa", value: 1200, description: "Tricorder",
        seller: "Daystrom Institute", afa_type: afa_types(:three_years),
        vat_percent: 0, private_use_percent: 0, interval: "once",
        date: Date.new(2026, 3, 1)
      }.merge(attributes))
    end

    it "writes off a share of the value for each year its type allows" do
      assert_equal 400.0, afa.afa_value(2026)
    end

    it "has written the whole value off once the years have passed" do
      assert_equal 0.0, afa.afa_value(2030)
    end

    # `date` is only validated on a one-off, so an interval leaves it empty
    # and the start of the interval is the day to count from. Reading
    # `date.year` raised — on a record the model considers valid, which took
    # the expenses list and its sums down with it.
    it "counts from the start of an interval when it has no date" do
      recurring = afa(interval: "monthly", date: nil, started_at: Date.new(2026, 3, 1))

      assert recurring.valid?, recurring.errors.full_messages.join(", ")
      assert_equal 400.0, recurring.afa_value(2026)
    end

    it "writes nothing off while it has no day to count from" do
      assert_equal 0.0, afa(date: nil, interval: "monthly", started_at: nil).afa_value(2026)
    end
  end
end
