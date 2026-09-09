# frozen_string_literal: true

require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }

  def valid_expense(overrides = {})
    data.account.expenses.create!({
      expense_type: "current", value: 10, description: "Test", seller: "ACME",
      date: Date.new(2025, 1, 1), private_use_percent: 0, vat_percent: 19, interval: "once"
    }.merge(overrides))
  end

  describe "unauthorized" do
    it "cannot bulk update" do
      post "/expenses/bulk_update", params: {expense_ids: ["x"], bulk: {vat_percent: "7"}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "authorized" do
    before do
      data.account.update_columns(feature_expenses: true)
      sign_in data
    end

    # The SPA owns the list, and the query travels with it: a bookmark on a
    # filtered list opens the same one.
    it "forwards the list to the spa" do
      get "/expenses"
      assert_redirected_to "/app/expenses"

      get "/expenses?year=2025&type=licenses"
      assert_redirected_to "/app/expenses?year=2025&type=licenses"
    end

    it "routes the pdf export to the list rather than the forward" do
      assert_recognizes(
        {controller: "expenses", action: "index", format: "pdf"},
        {path: "/expenses.pdf", method: :get}
      )
    end

    # The form cannot see which filters are on, so the SPA hands them over in
    # the url and the redirect after a save gives them back — which is what
    # `#index` used to remember on the way in.
    it "returns to the list the form was opened from" do
      get "/expenses/new?year=2025&type=licenses"

      post "/expenses", params: {
        expense: {
          expense_type: "licenses", value: "10", description: "Editor",
          seller: "ACME", date: "2025-01-01", private_use_percent: "0",
          vat_percent: "19", interval: "once"
        }
      }

      assert_response :found
      assert_includes response.location, "year=2025"
      assert_includes response.location, "type=licenses"
    end

    it "returns to the unfiltered list when the form was opened from one" do
      get "/expenses/new"

      post "/expenses", params: {
        expense: {
          expense_type: "licenses", value: "10", description: "Editor",
          seller: "ACME", date: "2025-01-01", private_use_percent: "0",
          vat_percent: "19", interval: "once"
        }
      }

      assert_response :found
      # Only the anchor of the row that was just saved, no filters.
      assert_match %r{/expenses#expense-}, response.location
      assert_not_includes response.location, "?"
    end

    it "returns to the list an edit was opened from" do
      expense = valid_expense

      get "/expenses/#{expense.id}/edit?year=2025"

      patch "/expenses/#{expense.id}", params: {expense: {description: "Renamed"}}

      assert_response :found
      assert_includes response.location, "year=2025"
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

    it "renders the form" do
      get "/expenses/new"

      assert_response :ok
    end

    it "bulk updates only the selected rows and only the provided fields" do
      selected = valid_expense(vat_percent: 19)
      untouched = valid_expense(vat_percent: 19)

      post "/expenses/bulk_update", params: {
        expense_ids: [selected.id], bulk: {vat_percent: "7", expense_type: "", private_use_percent: ""}
      }

      assert_response :found
      assert_equal 7, selected.reload.vat_percent
      assert_equal "current", selected.expense_type # blank field left unchanged
      assert_equal 19, untouched.reload.vat_percent # unselected row untouched
    end

    it "bulk destroys the selected rows" do
      doomed = valid_expense
      kept = valid_expense

      assert_difference -> { data.account.expenses.count }, -1 do
        post "/expenses/bulk_destroy", params: {expense_ids: [doomed.id]}
      end

      assert_nil Expense.find_by(id: doomed.id)
      assert Expense.find_by(id: kept.id)
    end

    it "reports a failure when nothing is selected" do
      post "/expenses/bulk_update", params: {expense_ids: [], bulk: {vat_percent: "7"}}

      assert_response :found
      assert_equal I18n.t(:"expenses.bulk.update_failure"), flash[:alert]
    end
  end
end
