# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  it "should validate email adresses" do
    user = User.new(password: "foofoo", password_confirmation: "foofoo", email: "foo @ bar .cccom")
    assert_not user.valid?
  end

  # The avatar is an URL, not markup: an escaped `&` in it names a parameter
  # `amp;r` instead of `r`, and the fallback it used to carry pointed at a
  # host GitHub retired, so the picture never arrived.
  describe "avatar" do
    let(:user) { users :data }

    it "asks gravatar for the size it was given" do
      assert_includes user.avatar(64), "s=64"
    end

    it "leaves the fallback to gravatar rather than a third host" do
      url = user.avatar

      assert_includes url, "d=identicon"
      assert_not_includes url, "identicons.github.com"
    end

    it "separates the parameters with plain ampersands" do
      assert_not_includes user.avatar, "&amp;"
      assert_equal 1, user.avatar.scan("s=").size
    end
  end
end
