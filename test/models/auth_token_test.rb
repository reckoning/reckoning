# frozen_string_literal: true

require 'test_helper'

class AuthTokenTest < ActiveSupport::TestCase
  it "should generate a valid token" do
    token = AuthToken.new(user_id: "80dfbd1f-aa6b-463c-a0ca-56d8ea205a72")
    assert token.valid?
    assert token.token
  end
end
