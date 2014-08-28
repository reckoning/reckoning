class InvoiceMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['MAILER_QUEUE'] || 'reckoning-mailer').to_sym

  def perform invoice_id
    invoice = Invoice.find invoice_id

    if invoice.present?
      InvoiceMailer.customer_mail(invoice).deliver
    end
  end
end
