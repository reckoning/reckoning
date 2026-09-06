# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def build_account(attributes = {})
    Account.new({
      name: "Stargazer",
      plan: "basic",
      users_attributes: [{
        email: "picard@star.fleet",
        password: "enterprise",
        password_confirmation: "enterprise"
      }]
    }.merge(attributes))
  end

  describe "signing up" do
    # The trial is what replaced the card: `stripe_token` and `stripe_email`
    # used to be required on create for anything but the free plan, which is
    # why the API could not register anyone.
    it "creates an account without any payment details" do
      account = build_account

      assert account.save, account.errors.full_messages.join(", ")
    end

    it "starts a fourteen day trial" do
      account = build_account
      account.save!

      assert account.trial_used?
      assert_in_delta 14.days.from_now, account.trial_end_at, 1.minute
    end

    it "leaves a free plan without a trial" do
      account = build_account(plan: "free")
      account.save!

      refute account.trial?
      assert_nil account.trial_end_at
    end
  end

  # The deploy window. `deploy.rb` migrates before it restarts, so for a
  # moment the old release is still serving — and its schema cache predates
  # these columns, so its INSERT does not name them. The column defaults are
  # what stands in: without them an account created in those seconds would
  # come out with no trial at all and keep write access forever.
  describe "an insert that does not name the trial columns" do
    it "still starts a trial" do
      id = ActiveRecord::Base.connection.select_value(<<~SQL)
        INSERT INTO accounts (name, plan, created_at, updated_at)
        VALUES ('Deploy Window', 'basic', now(), now())
        RETURNING id
      SQL

      account = Account.find(id)

      assert account.trial_active?
      assert account.trial_used?
      assert_in_delta 14.days.from_now, account.trial_end_at, 1.minute
    end
  end

  describe "trial state" do
    it "is active while the end date is ahead" do
      account = build_account
      account.save!

      assert account.trial_active?
      refute account.trial_expired?
    end

    it "is expired once the end date passes" do
      account = build_account
      account.save!
      account.update!(trial_end_at: 1.minute.ago)

      refute account.trial_active?
      assert account.trial_expired?
    end

    # An account that never had a trial — grandfathered, or on a free plan —
    # is not an expired one.
    it "counts a missing end date as no trial rather than an expired one" do
      account = build_account
      account.save!
      account.update!(trial_end_at: nil, trial_used: false)

      refute account.trial_active?
      refute account.trial_expired?
    end

    it "rounds the days left up" do
      account = build_account
      account.save!

      account.update!(trial_end_at: 8.hours.from_now)
      assert_equal 1, account.trial_days_left

      account.update!(trial_end_at: 3.days.from_now + 2.hours)
      assert_equal 4, account.trial_days_left

      account.update!(trial_end_at: 1.minute.ago)
      assert_equal 0, account.trial_days_left
    end
  end
end
