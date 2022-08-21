# frozen_string_literal: true

require 'test_helper'

class InvoiceMailerTest < ActionMailer::TestCase
  let(:invoice) { invoices :january }

  before do
    invoice.customer.email_template = 'Hallo Foo'
    invoice.customer.invoice_email = 'test@customer.me'
    invoice.customer.save
  end

  describe '#customer' do
    it 'sends email to default from if nothing is defined' do
      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.me'], mail.to
      assert_equal ['noreply@reckoning.me'], mail.from
    end

    it 'sends email to global from address' do
      invoice.account.default_from = 'user@reckoning.me'
      invoice.account.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.me'], mail.to
      assert_equal ['user@reckoning.me'], mail.from
    end

    it 'sends email to customer from address' do
      invoice.customer.default_from = 'special-customer@reckoning.me'
      invoice.customer.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.me'], mail.to
      assert_equal ['special-customer@reckoning.me'], mail.from
    end

    it 'falls back to default from address if global email is empty string' do
      invoice.account.default_from = ''
      invoice.account.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ['test@customer.me'], mail.to
      assert_equal ['noreply@reckoning.me'], mail.from
    end
  end
end
