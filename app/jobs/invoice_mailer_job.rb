class InvoiceMailerJob
  @queue = (ENV['MAILER_QUEUE'] || '').to_sym

  def self.perform invoice_id
    invoice = Invoice.find invoice_id

    if invoice.present?
      InvoiceMailer.customer_mail(invoice).deliver
    end
  end
end
