# encoding: utf-8
# frozen_string_literal: true
require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  fixtures :all

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

    assert_response :ok

    assert_equal I18n.t(:"devise.failure.invalid"), flash[:alert]
  end
end
