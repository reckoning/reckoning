# encoding: utf-8
class InvoicePdfWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['BILLING_QUEUE'] || 'reckoning-billing').to_sym

  def perform invoice_id
    invoice = Invoice.find invoice_id
    begin
      invoice.generate
      invoice.generate_timesheet if invoice.timers.present?

      invoice.update_attributes(pdf_generated_at: Time.now)
    rescue Exception => e
      Rails.logger.debug e.inspect
    ensure
      invoice.update_attributes(pdf_generating: false)
    end
  end
end
