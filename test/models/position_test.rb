# frozen_string_literal: true

require 'test_helper'

class PositionTest < ActiveSupport::TestCase
  it 'should not be valid if description is missing' do
    position = Position.new
    assert_not position.valid?, "#{position.inspect} should be invalid"
  end

  it 'should not be valid if invoice is missing' do
    position = Position.new(description: 'foo')
    assert_not position.valid?, "#{position.inspect} should be invalid"
  end

  it 'should set the correct value on save for position and invoice' do
    position = Position.new rate: 22.0, hours: 10.0

    assert_equal position.hours * position.rate, position.set_value.to_f
  end

  it 'should respond to invoice' do
    position = Position.new
    assert_respond_to position, :invoicable
  end
end
