# frozen_string_literal: true

require "test_helper"

class ExpenseImportsControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }

  describe "unauthorized" do
    it "cannot open the import form" do
      get "/expense_imports/new"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "authorized" do
    before do
      data.account.update_columns(feature_expenses: true)
      sign_in data
    end

    it "shows the upload form" do
      get "/expense_imports/new"

      assert_response :ok
    end

    it "parses an ADAC file into an editable preview, skipping the credit row" do
      post "/expense_imports/preview", params: {
        expense_import: {
          file: fixture_file_upload("adac_credit_card.csv", "text/csv"),
          expense_type: "licenses",
          vat_percent: "19"
        }
      }

      assert_response :ok
      assert_select "input[name=?]", "expense_import[rows][0][seller]"
      assert_select "input[name=?]", "expense_import[rows][1][seller]"
      # the credit (positive) row is skipped, so there is no third row
      assert_select "input[name=?]", "expense_import[rows][2][seller]", count: 0
    end

    it "creates expenses from the selected, edited rows" do
      assert_difference -> { data.account.expenses.count }, 1 do
        post "/expense_imports", params: {
          expense_import: {
            rows: {
              "0" => {include: "1", date: "2025-07-03", value: "7.96", seller: "Dnsimple",
                      description: "DNS", expense_type: "licenses", vat_percent: "19",
                      private_use_percent: "0", interval: "once"},
              "1" => {include: "0", date: "2025-06-25", value: "6.38", seller: "Skip",
                      description: "skip", expense_type: "licenses", vat_percent: "19",
                      private_use_percent: "0", interval: "once"}
            }
          }
        }
      end

      assert_response :found
      assert_equal "Dnsimple", data.account.expenses.order(:created_at).last.seller
      assert_equal I18n.t(:"resources.messages.import.success", resource: I18n.t(:"resources.expense")), flash[:success]
    end

    it "keeps the active list filter after importing" do
      get "/expenses", params: {year: "2025", type: "licenses"}

      post "/expense_imports", params: {
        expense_import: {
          rows: {"0" => {include: "1", date: "2025-07-03", value: "7.96", seller: "X",
                         description: "Y", expense_type: "licenses", vat_percent: "19",
                         private_use_percent: "0", interval: "once"}}
        }
      }

      assert_response :found
      assert_includes response.location, "year=2025"
      assert_includes response.location, "type=licenses"
    end
  end
end
