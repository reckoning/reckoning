# frozen_string_literal: true

require "test_helper"

class InvoiceMailerTest < ActionMailer::TestCase
  let(:invoice) { invoices :january }

  before do
    invoice.customer.email_template = "Hallo Foo"
    invoice.customer.invoice_email = "test@customer.me"
    invoice.customer.save
  end

  describe "#customer" do
    it "sends email to default from" do
      invoice.account.contact_information["public_email"] = "user@reckoning.me"
      invoice.account.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ["test@customer.me"], mail.to
      assert_equal ["noreply@reckoning.me"], mail.from
      assert_equal ["user@reckoning.me"], mail.cc
      assert_nil mail.bcc
    end

    it "sends email to configured cc and bcc recipients" do
      invoice.account.contact_information["public_email"] = "user@reckoning.me"
      invoice.account.save

      invoice.customer.update(
        invoice_email_cc: "cc@reckoning.me",
        invoice_email_bcc: "bcc@reckoning.me,bcc1@reckoning.me"
      )

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ["test@customer.me"], mail.to
      assert_equal ["noreply@reckoning.me"], mail.from
      assert_equal ["cc@reckoning.me", "user@reckoning.me"], mail.cc
      assert_equal ["bcc@reckoning.me", "bcc1@reckoning.me"], mail.bcc
    end

    it "sends email to users email if public_email is empty" do
      invoice.account.contact_information["public_email"] = nil
      invoice.account.save

      mail = InvoiceMailer.customer(invoice).deliver_now

      assert_not ActionMailer::Base.deliveries.empty?

      assert_equal ["test@customer.me"], mail.to
      assert_equal ["noreply@reckoning.me"], mail.from
      assert_equal [], mail.cc
      assert_equal invoice.account.users.pluck(:email), mail.bcc
    end
  end
end
