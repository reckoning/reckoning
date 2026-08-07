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

    it "renders the index with per-row and select-all checkboxes" do
      valid_expense

      get "/expenses"

      assert_response :ok
      assert_select "[data-controller=bulk-select]"
      assert_select "input[data-bulk-select-target=selectAll]"
      assert_select "input[name='expense_ids[]']"
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
