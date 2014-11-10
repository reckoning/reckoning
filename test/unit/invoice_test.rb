require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  fixtures :projects, :invoices, :positions, :timers, :weeks, :tasks

  it "should not be valid without project" do
    invoice = Invoice.new(customer_id: "foo", project_id: nil)
    assert !invoice.valid?, "#{invoice.inspect} should be invalid"
  end

  it "should not be valid without date" do
    invoice = Invoice.new(date: nil)
    assert !invoice.valid?, "#{invoice.inspect} should be invalid"
  end

  it "should not be valid without customer" do
    invoice = Invoice.new(customer_id: nil)
    assert !invoice.valid?, "#{invoice.inspect} should be invalid"
  end

  it "should create invoice if date and valid project present" do
    Timecop.freeze "2014-01-01" do
      project = projects :enterprise
      invoice = Invoice.new(project_id: project.id, date: Time.now)
      assert invoice.valid?, "#{invoice.inspect} should be valid"
    end
  end

  describe "pdf generation" do
    let(:invoice) { invoices :february }
    let(:warpcore) { positions :warpcore }

    before do
      PdfGenerator.any_instance.stubs(:call_pdf_lib).returns(nil)

      warpcore.timers << timers(:twohours)
      warpcore.timers << timers(:threehours)
      invoice.positions << warpcore
      invoice.save
    end

    it "creates timesheet if timers present" do
      assert_nothing_raised do
        invoice.generate_timesheet
        invoice.generate
      end
    end
  end

  it "should have a unique ref scoped by user"

  it "before_create set_ref"

  it "before_save set_rate"

  it "before_save set_value"

  it "should only set set_payment_due_date if payment_due_date empty"

  it "should respond to defined associations" do
    invoice = Invoice.new
    assert_respond_to invoice, :user
    assert_respond_to invoice, :customer
    assert_respond_to invoice, :project
    assert_respond_to invoice, :positions
  end
end
