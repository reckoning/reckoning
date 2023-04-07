# frozen_string_literal: true

require "test_helper"

class InvoiceMailerWorkerTest < ActionMailer::TestCase
  let(:invoice) { invoices :january }

  before do
    invoice.customer.email_template = "Hallo Foo"
    invoice.customer.invoice_email = "test@customer.io"
    invoice.customer.save
  end

  it "send email for invoice" do
    InvoiceMailerWorker.perform_async(invoice.id)
    assert_equal 1, InvoiceMailerWorker.jobs.size

    InvoiceMailerWorker.drain
    assert_equal 0, InvoiceMailerWorker.jobs.size

    assert_not ActionMailer::Base.deliveries.empty?
  end
end
