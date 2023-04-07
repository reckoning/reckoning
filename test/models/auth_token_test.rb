# frozen_string_literal: true

require "test_helper"

class AuthTokenTest < ActiveSupport::TestCase
  it "should generate a valid token" do
    user = users :data
    token = AuthToken.new(user: user)

    assert token.valid?
    assert token.token
  end
end
