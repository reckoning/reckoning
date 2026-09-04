# frozen_string_literal: true

require "test_helper"

class TrialTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }
  let(:account) { accounts(:enterprise) }
  let(:customer) { customers(:starfleet) }

  def trial_ending(when_)
    account.update_columns(plan: "basic", trial_used: true, trial_end_at: when_)
  end

  describe "after the trial" do
    it "explains a refused write instead of shrugging" do
      trial_ending(1.minute.ago)
      sign_in user

      patch customer_path(customer), params: {customer: {name: "Renamed"}}

      assert_redirected_to root_url
      assert_equal I18n.t("trial.denied"), flash[:alert]
      assert_equal "Starfleet", customer.reload.name
    end

    it "still serves the screens the data lives on" do
      trial_ending(1.minute.ago)
      sign_in user

      get invoices_path

      assert_response :success
    end
  end
end
