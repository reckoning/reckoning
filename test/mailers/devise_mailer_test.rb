# frozen_string_literal: true

require "test_helper"

# Devise hands the mailer the raw token and stores only its digest, so a
# template that reads the token off the record mails the digest instead —
# which `*_by_token` then digests a second time and never matches. The unlock
# mail did exactly that, and since lockout is `:failed_attempts` with
# `:email` as the only way back, the link a locked-out account depends on
# never worked. Each token-bearing mail is checked by using its link, not by
# looking at it.
class DeviseMailerTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }

  it "mails an unlock token that unlocks the account" do
    user.lock_access!(send_instructions: false)
    user.send_unlock_instructions

    token = emailed_token(:unlock_token)
    unlocked = User.unlock_access_by_token(token)

    assert_empty unlocked.errors
    refute user.reload.access_locked?
  end

  it "mails a confirmation token that confirms the address" do
    user.update!(email: "riker@star.fleet")

    token = emailed_token(:confirmation_token)
    confirmed = User.confirm_by_token(token)

    assert_empty confirmed.errors
    assert_equal "riker@star.fleet", user.reload.email
  end

  it "mails a reset token that lets the password be set" do
    user.send_reset_password_instructions

    token = emailed_token(:reset_password_token)
    reset = User.reset_password_by_token(
      reset_password_token: token,
      password: "newpassword",
      password_confirmation: "newpassword"
    )

    assert_empty reset.errors
    assert user.reload.valid_password?("newpassword")
  end

  private def emailed_token(param)
    mail = ActionMailer::Base.deliveries.last

    assert mail, "no mail was delivered"

    token = mail.body.to_s[/#{param}=([^"&]+)/, 1]

    assert token, "the mail carried no #{param}"

    CGI.unescape(token)
  end
end
