require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase

  def teardown
    Customer.destroy_all
    Project.destroy_all
    Invoice.destroy_all
  end

  test "should not be valid without project" do
    invoice = build(:invoice, project_id: nil)
    assert !invoice.valid?, "#{invoice.inspect} should be invalid"
  end

  test "should not be valid without date" do
    invoice = build(:invoice, date: nil)
    assert !invoice.valid?, "#{invoice.inspect} should be invalid"
  end

  test "should not be valid without customer" do
    invoice = build(:invoice, customer_id: nil, project_id: nil)
    assert !invoice.valid?, "#{invoice.inspect} should be invalid"
  end

  test "should create invoice if date and valid project present" do
    project = create(:project)
    invoice = build(:invoice, project_id: project.id, date: Time.now)
    assert invoice.save, "#{invoice.inspect} should be created"
  end

  test "should have a unique ref scoped by user" do
    skip("needs to be tested!")
  end

  test "before_create set_ref" do
    skip("needs to be tested!")
  end

  test "before_save set_rate" do
    skip("needs to be tested!")
  end

  test "before_save set_value" do
    skip("needs to be tested!")
  end

  test "should only set set_payment_due_date if payment_due_date empty" do
    skip("needs to be tested!")
  end

  test "should respond to defined associations" do
    invoice = build(:invoice)
    assert_respond_to invoice, :user
    assert_respond_to invoice, :customer
    assert_respond_to invoice, :project
    assert_respond_to invoice, :positions
  end
end
