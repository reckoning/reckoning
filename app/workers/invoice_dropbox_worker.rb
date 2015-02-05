require 'dropbox_sdk'

class InvoiceDropboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['ARCHIVE_QUEUE'] || 'reckoning-archive').to_sym

  def perform(invoice_id)
    invoice = Invoice.find invoice_id
    return if invoice.blank?

    client = ::DropboxClient.new(invoice.account.dropbox_token)

    base_path = [
      invoice.customer.name.gsub('/', '-').strip,
      invoice.project.name.gsub('/', '-').strip
    ]

    if File.exist?(invoice.pdf_path)
      path = (base_path + [
        invoice.invoice_file
      ]).join("/")
      client.put_file(path, open(invoice.pdf_path), true)
    end

    return unless File.exist?(invoice.timesheet_path)
    path = (base_path + [
      invoice.timesheet_file
    ]).join("/")
    client.put_file(path, open(invoice.timesheet_path), true)
  end
end
