class InvoiceTestMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['MAILER_QUEUE'] || 'reckoning-mailer').to_sym

  def perform invoice_id, test_mail
    invoice = Invoice.find invoice_id

    if invoice.present?
      InvoiceMailer.test_mail(invoice, test_mail).deliver_now
    end
  end
end
