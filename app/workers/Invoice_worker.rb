# encoding: utf-8
class InvoiceWorker
  @queue = (ENV['BILLING_QUEUE'] || '').to_sym

  def self.perform invoice_id
    invoice = Invoice.find invoice_id
    invoice.generate

    invoice.update_attributes({pdf_generating: false, pdf_generated_at: Time.now})

    #CustomerMailer.invoice_notification(invoice).deliver
  end
end
