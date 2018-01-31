# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  it "should validate email adresses" do
    user = User.new(password: "foofoo", password_confirmation: "foofoo", email: "foo @ bar .cccom")
    assert !user.valid?
  end
end
