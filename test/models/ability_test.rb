# frozen_string_literal: true

require "test_helper"

class AbilityTest < ActiveSupport::TestCase
  let(:user) { users(:will) }
  let(:account) { accounts(:enterprise) }
  let(:customer) { customers(:starfleet) }

  def expire_trial
    account.update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)
    user.reload
  end

  def run_trial
    account.update_columns(plan: "basic", trial_used: true, trial_end_at: 5.days.from_now)
    user.reload
  end

  describe "while the trial runs" do
    it "leaves the account able to work" do
      run_trial
      ability = Ability.new(user)

      assert ability.can?(:create, Customer.new(account_id: account.id))
      assert ability.can?(:manage, customer)
    end
  end

  describe "once the trial has expired" do
    it "still reads the account's own data" do
      expire_trial
      ability = Ability.new(user)

      assert ability.can?(:read, customer)
      assert ability.can?(:show, :timesheet)
      assert ability.can?(:read, user)
    end

    it "stops anything being created or changed" do
      expire_trial
      ability = Ability.new(user)

      refute ability.can?(:create, Customer.new(account_id: account.id))
      refute ability.can?(:update, customer)
      refute ability.can?(:destroy, customer)
    end

    # The reason the read-only rules are written out rather than layered on
    # with `cannot`: `can :manage` covers these too, and a blanket
    # create/update/destroy ban would leave every one of them open.
    it "stops the custom actions as well" do
      expire_trial
      ability = Ability.new(user)
      invoice = invoices(:january)
      timer = timers(:twohours)

      refute ability.can?(:send, invoice)
      refute ability.can?(:check, invoice)
      refute ability.can?(:charge, invoice)
      refute ability.can?(:manage, timer)
    end

    it "keeps another account's data out of reach" do
      expire_trial
      ability = Ability.new(user)

      refute ability.can?(:read, customers(:defiant_customer))
    end

    # Settings stay reachable so the account can be put right.
    it "still lets the account itself be edited" do
      expire_trial
      ability = Ability.new(user)

      assert ability.can?(:update, account)
    end

    it "does not restrict an admin" do
      expire_trial
      user.update_columns(admin: true)
      ability = Ability.new(user.reload)

      assert ability.can?(:manage, Account)
    end
  end

  describe "an account that never had a trial" do
    it "is not treated as expired" do
      account.update_columns(trial_end_at: nil, trial_used: false)
      ability = Ability.new(user.reload)

      assert ability.can?(:create, Customer.new(account_id: account.id))
    end
  end
end
