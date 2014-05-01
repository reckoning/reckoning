class InvoiceTestMailerJob
  @queue = (ENV['MAILER_QUEUE'] || '').to_sym

  def self.perform invoice_id, test_mail
    invoice = Invoice.find invoice_id

    if invoice.present?
      InvoiceMailer.test_mail(invoice, test_mail).deliver
    end
  end
end
