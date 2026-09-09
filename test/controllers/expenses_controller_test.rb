# frozen_string_literal: true

require "test_helper"

# All that is left of the server-rendered expense: the two exports, and the
# paths that hand the rest over to the SPA.
class ExpensesControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }

  def valid_expense(overrides = {})
    data.account.expenses.create!({
      expense_type: "current", value: 10, description: "Test", seller: "ACME",
      date: Date.new(2025, 1, 1), private_use_percent: 0, vat_percent: 19, interval: "once"
    }.merge(overrides))
  end

  describe "unauthorized" do
    # A csv request is not a navigation, so Devise answers rather than
    # sending the browser to the login screen.
    it "does not export" do
      get "/expenses.csv"

      assert_response :unauthorized
    end
  end

  describe "authorized" do
    before do
      data.account.update_columns(feature_expenses: true)
      sign_in data
    end

    # The query travels with it, so a bookmark on a filtered list opens the
    # same one.
    it "forwards the list, the form and an edit to the spa" do
      expense = valid_expense

      get "/expenses"
      assert_redirected_to "/app/expenses"

      get "/expenses?year=2025&type=licenses"
      assert_redirected_to "/app/expenses?year=2025&type=licenses"

      get "/expenses/new?type=licenses"
      assert_redirected_to "/app/expenses/new?type=licenses"

      get "/expenses/#{expense.id}/edit?year=2025"
      assert_redirected_to "/app/expenses/#{expense.id}/edit?year=2025"
    end

    # Nothing asked for the csv, which is how a 500 sat in it unnoticed.
    it "answers the csv export" do
      valid_expense

      get "/expenses.csv"

      assert_response :ok
      assert_equal "text/csv", response.media_type
      assert_includes response.body, "description"
      assert_includes response.body, "Test"
    end

    it "exports only what the filter leaves" do
      valid_expense(description: "Kept", date: Date.new(2025, 1, 1))
      valid_expense(description: "Dropped", date: Date.new(2024, 1, 1))

      get "/expenses.csv?year=2025"

      assert_includes response.body, "Kept"
      assert_not_includes response.body, "Dropped"
    end

    # Both exports are the same path in another format, which the forward has
    # to let past rather than swallow.
    it "routes the pdf export to the list rather than the forward" do
      assert_recognizes(
        {controller: "expenses", action: "index", format: "pdf"},
        {path: "/expenses.pdf", method: :get}
      )
    end
  end
end
