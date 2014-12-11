class InvoiceMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['MAILER_QUEUE'] || 'reckoning-mailer').to_sym

  def perform invoice_id, count = 1
    invoice = Invoice.find invoice_id

    if invoice.present?
      if invoice.files_present?
        InvoiceMailer.customer_mail(invoice).deliver
      elsif count <= 3
        InvoiceMailerWorker.perform_in 2.minutes, self.id, count + 1
      end
    end
  end
end
