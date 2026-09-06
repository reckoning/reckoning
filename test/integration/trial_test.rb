# frozen_string_literal: true

require "test_helper"

class TrialTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }
  let(:account) { accounts(:enterprise) }
  let(:project) { projects(:narendra3) }

  def trial_ending(when_)
    account.update_columns(plan: "basic", trial_used: true, trial_end_at: when_)
  end

  describe "the banner" do
    it "counts the days down" do
      trial_ending(5.days.from_now)
      sign_in user

      get root_path

      assert_select "[data-test=?]", "trial-banner", text: /noch 5 Tage/
    end

    it "says so once the trial is over" do
      trial_ending(1.minute.ago)
      sign_in user

      get root_path

      assert_select "[data-test=?]", "trial-banner", text: /abgelaufen/
    end

    it "stays away from an account that has no trial" do
      account.update_columns(trial_end_at: nil, trial_used: false)
      sign_in user

      get root_path

      assert_select "[data-test=?]", "trial-banner", false
    end
  end

  describe "after the trial" do
    it "explains a refused write instead of shrugging" do
      trial_ending(1.minute.ago)
      sign_in user

      patch project_path(project), params: {project: {name: "Renamed"}}

      assert_redirected_to root_url
      assert_equal I18n.t("trial.denied"), flash[:alert]
      assert_equal "Narendra 3", project.reload.name
    end

    it "still serves the screens the data lives on" do
      trial_ending(1.minute.ago)
      sign_in user

      get invoices_path

      assert_response :success
    end
  end
end
