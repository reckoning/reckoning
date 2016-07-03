# encoding: utf-8
# frozen_string_literal: true
class InvoiceTestMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['MAILER_QUEUE'] || 'reckoning-mailer').to_sym

  def perform(invoice_id, test_mail)
    invoice = Invoice.find invoice_id

    return if invoice.blank?

    InvoiceMailer.test(invoice, test_mail).deliver_now
  end
end
