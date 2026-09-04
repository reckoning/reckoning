# frozen_string_literal: true

require "test_helper"

# Confirmation, unlock and password reset moved to the SPA in phase B2, but
# Devise's mailers keep building the /users/… urls — and links it sent before
# the move are already in people's inboxes. Those urls now forward, token and
# all.
class SpaAuthLinksTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }

  it "forwards a confirmation link with its token" do
    get "/users/confirmation", params: {confirmation_token: "a-token"}

    assert_redirected_to "/app/confirmation?confirmation_token=a-token"
  end

  it "forwards an unlock link with its token" do
    get "/users/unlock", params: {unlock_token: "a-token"}

    assert_redirected_to "/app/unlock?unlock_token=a-token"
  end

  it "forwards a password reset link with its token" do
    get "/users/password/edit", params: {reset_password_token: "a-token"}

    assert_redirected_to "/app/password/edit?reset_password_token=a-token"
  end

  it "forwards the request forms that carry no token" do
    get "/users/password/new"
    assert_redirected_to "/app/password/new"

    get "/users/confirmation/new"
    assert_redirected_to "/app/confirmation"

    get "/users/unlock/new"
    assert_redirected_to "/app/unlock"
  end

  # The promise is about the mails themselves, so follow a real one rather
  # than a hand-written path. Whether the token in it actually works is
  # DeviseMailerTest's job.
  it "forwards the link a real unlock mail carries" do
    user.lock_access!(send_instructions: false)
    user.send_unlock_instructions

    get emailed_path(%r{/users/unlock\?unlock_token=[^"]+})

    assert_match %r{/app/unlock\?unlock_token=.+\z}, response.location
  end

  it "forwards the link a real confirmation mail carries" do
    user.update!(email: "riker@star.fleet")

    get emailed_path(%r{/users/confirmation\?confirmation_token=[^"]+})

    assert_match %r{/app/confirmation\?confirmation_token=.+\z}, response.location
  end

  private def emailed_path(pattern)
    mail = ActionMailer::Base.deliveries.last

    assert mail, "no mail was delivered"

    path = mail.body.to_s[pattern]

    assert path, "the mail carried no link matching #{pattern.inspect}"

    path
  end
end
