# encoding: utf-8
class InvoicePdfJob
  @queue = (ENV['BILLING_QUEUE'] || '').to_sym

  def self.perform invoice_id
    invoice = Invoice.find invoice_id
    begin
      invoice.generate
      invoice.generate_timesheet if invoice.timers.present?

      invoice.update_attributes(pdf_generated_at: Time.now)

      if invoice.user.has_gdrive?
        Resque.enqueue InvoiceGdriveJob, invoice.id
      end
    rescue Exception => e
      Rails.logger.debug e.inspect
    ensure
      invoice.update_attributes(pdf_generating: false)
    end
  end
end
