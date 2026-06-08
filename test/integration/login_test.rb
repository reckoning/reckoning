# frozen_string_literal: true

require "test_helper"

class LoginTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }

  it "login with valid credentials redirects and gives correct success message" do
    get "/signin"

    assert_select "#new_user"
    assert_response :success

    post "/signin", params: {
      user: {
        email: user.email,
        password: "enterprise"
      }
    }
    follow_redirect!

    assert_nil flash[:alert]

    assert_equal root_path, path

    assert_select ".user-email", user.email.to_s

    assert_equal I18n.t(:"devise.sessions.signed_in"), flash[:notice]
  end

  it "login with invalid credentials redirects and gives correct alert message" do
    get "/signin"

    assert_select "#new_user"

    # user submits form
    post "/signin", params: {
      user: {
        email: user.email,
        password: "foo"
      }
    }

    # Devise.responder.error_status is set to :unprocessable_entity
    # (422) in config/initializers/devise.rb so Turbo Drive renders
    # the form-error response in place. Was :ok (200) prior — the
    # default for Devise 5.x without the override.
    assert_response :unprocessable_entity

    assert_equal I18n.t(:"devise.failure.invalid"), flash[:alert]
  end
end
