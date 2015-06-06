class InvoiceMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['MAILER_QUEUE'] || 'reckoning-mailer').to_sym

  def perform(invoice_id, count = 1)
    invoice = Invoice.find invoice_id

    return if invoice.blank?

    if invoice.files_present?
      InvoiceMailer.customer_mail(invoice).deliver_now
    elsif count <= 3
      InvoiceMailerWorker.perform_in 2.minutes, invoice_id, count + 1
    end
  end
end
