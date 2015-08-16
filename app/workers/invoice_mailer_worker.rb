class InvoiceMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['MAILER_QUEUE'] || 'reckoning-mailer').to_sym

  def perform(invoice_id)
    invoice = Invoice.find invoice_id

    return if invoice.blank?

    InvoiceMailer.customer(invoice).deliver_now
  end
end
