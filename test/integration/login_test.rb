require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
  end

  def tear_down
    User.delete_all
  end

  test "login with valid credentials redirects and gives correct success message" do
    get "/signin"

    assert_select "#new_user"
    assert_response :success

    post_via_redirect "/signin", {
      user: {
        email: @user.email,
        password: @user.password
      }
    }
    assert_equal nil, flash[:alert]

    assert_equal root_path, path

    assert_select ".user-email", "#{@user.email}"

    assert_equal I18n.t(:"devise.sessions.signed_in"), flash[:notice]
  end

  test "login with invalid credentials redirects and gives correct alert message" do
    get "/signin"

    assert_select "#new_user"

    # user submits form
    post "/signin", {
      user: {
        email: @user.email,
        password: "foo"
      }
    }

    assert_response :ok

    assert_equal I18n.t(:"devise.failure.invalid"), flash[:alert]
  end

end
