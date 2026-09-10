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
    # The API is the only writer left: every server-rendered write has moved
    # into it, so it is the only place that can explain a refusal.
    it "explains a refused write instead of shrugging" do
      trial_ending(1.minute.ago)
      sign_in user

      assert_no_difference "Customer.count" do
        post "/api/v1/customers",
          params: {name: "Andorian Guard"}.to_json,
          headers: {"Content-Type" => "application/json", "Accept" => "application/json"}
      end

      assert_response :forbidden
      assert_equal "trial.expired", JSON.parse(response.body)["code"]
      assert_equal I18n.t("trial.denied"), JSON.parse(response.body)["message"]
    end

    # A refusal that is not about the trial keeps saying what it is.
    it "leaves another refusal to say its own thing" do
      account.update_columns(plan: "basic", trial_used: true, trial_end_at: 5.days.from_now)
      sign_in user

      post "/api/v1/backend/users",
        params: {email: "q@continuum"}.to_json,
        headers: {"Content-Type" => "application/json", "Accept" => "application/json"}

      assert_response :forbidden
      assert_equal "forbidden", JSON.parse(response.body)["code"]
    end

    # The refusals an expired trial does *not* cause keep their own code. A
    # read is the case worth watching — the trial leaves reads alone — and
    # the two guards that refuse one answer before CanCan does, each with its
    # own reason: expenses that are switched off say `feature.disabled`, and
    # another account's record is not found rather than refused.
    it "leaves a read to say its own thing" do
      trial_ending(1.minute.ago)
      account.update_columns(feature_expenses: false)
      sign_in user

      get "/api/v1/expenses", headers: {"Accept" => "application/json"}

      assert_response :forbidden
      assert_equal "feature.disabled", JSON.parse(response.body)["code"]

      get "/api/v1/invoices/#{invoices(:february).id}", headers: {"Accept" => "application/json"}

      assert_response :not_found
    end

    it "still serves the screens the data lives on" do
      trial_ending(1.minute.ago)
      sign_in user

      get root_path

      assert_response :success
      assert_select "div#spa"
    end
  end
end
