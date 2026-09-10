# frozen_string_literal: true

require "test_helper"

class TrialTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }
  let(:account) { accounts(:enterprise) }
  let(:expense) { expenses(:one) }

  def trial_ending(when_)
    account.update_columns(plan: "basic", trial_used: true, trial_end_at: when_)
  end

  # `/impressum` is the last screen on the server-rendered layout the banner
  # lives in — the root path hands a signed-in user to the SPA now, which
  # renders its own.
  describe "the banner" do
    it "counts the days down" do
      trial_ending(5.days.from_now)
      sign_in user

      get "/impressum"

      assert_select "[data-test=?]", "trial-banner", text: /noch 5 Tage/
    end

    it "says so once the trial is over" do
      trial_ending(1.minute.ago)
      sign_in user

      get "/impressum"

      assert_select "[data-test=?]", "trial-banner", text: /abgelaufen/
    end

    it "stays away from an account that has no trial" do
      account.update_columns(trial_end_at: nil, trial_used: false)
      sign_in user

      get "/impressum"

      assert_select "[data-test=?]", "trial-banner", false
    end
  end

  describe "after the trial" do
    # Any server-rendered write will do; the CSV import is simply the one
    # that has not moved to the SPA yet — the expense form it used to be has.
    it "explains a refused write instead of shrugging" do
      trial_ending(1.minute.ago)
      sign_in user

      assert_no_difference "Expense.count" do
        post expense_imports_path, params: {
          expense_import: {
            rows: {"0" => {include: "1", date: "2025-07-03", value: "7.96", seller: "X",
                           description: "Y", expense_type: "licenses", vat_percent: "19",
                           private_use_percent: "0", interval: "once"}}
          }
        }
      end

      assert_redirected_to root_url
      assert_equal I18n.t("trial.denied"), flash[:alert]
    end

    it "still serves the screens the data lives on" do
      trial_ending(1.minute.ago)
      sign_in user

      get root_path

      assert_redirected_to spa_path
      follow_redirect!
      assert_response :success
    end
  end
end
