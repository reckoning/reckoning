require 'test_helper'

class PositionTest < ActiveSupport::TestCase

  def teardown
    Customer.destroy_all
    Project.destroy_all
    Invoice.destroy_all
    Position.destroy_all
  end

  test "should not be valid if description is missing" do
    position = build(:position, invoice: nil)
    assert !position.valid?, "#{position.inspect} should be invalid"
  end

  test "should not be valid if invoice is missing" do
    position = build(:position, description: nil)
    assert !position.valid?, "#{position.inspect} should be invalid"
  end

  test "should set the correct value on save for position and invoice" do
    hours = 10.0
    rate = 22.0
    invoice = create(:invoice)
    position = create(:position, invoice_id: invoice.id, rate: rate, hours: hours)
    assert_equal hours * rate, position.value.to_f
    assert_equal hours * rate, invoice.reload.value.to_f
  end

  test "should respond to invoice" do
    position = build(:position)
    assert_respond_to position, :invoice
  end
end
