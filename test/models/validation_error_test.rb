# frozen_string_literal: true

require "test_helper"

class ValidationErrorTest < ActiveSupport::TestCase
  it "should respond to code, message and errors" do
    validation_error = ValidationError.new("code", "message")
    assert_respond_to validation_error, :code
    assert_respond_to validation_error, :message
    assert_respond_to validation_error, :errors
  end
end
