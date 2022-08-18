# frozen_string_literal: true

require 'test_helper'

class InvoiceMailerTest < ActionMailer::TestCase
  let(:invoice) { invoices :january }

  before do
    invoice.customer.email_template = 'Hallo Foo'
    invoice.customer.invoice_email = 'test@customer.cc'
    invoice.customer.save
  end

  describe '#customer' do
    it 'sends email to default from if nothing is defined' do
      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.cc'], mail.to
      assert_equal ['noreply@reckoning.cc'], mail.from
    end

    it 'sends email to global from address' do
      invoice.account.default_from = 'user@reckoning.cc'
      invoice.account.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.cc'], mail.to
      assert_equal ['user@reckoning.cc'], mail.from
    end

    it 'sends email to customer from address' do
      invoice.customer.default_from = 'special-customer@reckoning.cc'
      invoice.customer.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.cc'], mail.to
      assert_equal ['special-customer@reckoning.cc'], mail.from
    end

    it 'falls back to default from address if global email is empty string' do
      invoice.account.default_from = ''
      invoice.account.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.cc'], mail.to
      assert_equal ['noreply@reckoning.cc'], mail.from
    end
  end
end
