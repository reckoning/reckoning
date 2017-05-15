# encoding: utf-8
# frozen_string_literal: true

require 'test_helper'

class TimerMailerTest < ActionMailer::TestCase
  let(:timer) { timers :twohours }

  it "sends email user with long running timer" do
    mail = TimerMailer.notify(timer).deliver_now

    refute ActionMailer::Base.deliveries.empty?

    assert_equal [timer.user.email], mail.to
    assert_equal ["noreply@reckoning.io"], mail.from
  end
end
