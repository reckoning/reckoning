# frozen_string_literal: true

require "dropbox_sdk"

class InvoiceDropboxWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV["ARCHIVE_QUEUE"] || "reckoning-archive").to_sym

  def perform(invoice_id)
    invoice = Invoice.find invoice_id
    return if invoice.blank?

    client = ::DropboxClient.new(invoice.account.dropbox_token)

    base_path = [
      invoice.customer.name.tr("/", "-").strip,
      invoice.project.name.tr("/", "-").strip
    ]

    path = (base_path + [
      "#{invoice.invoice_file}.pdf"
    ]).join("/")
    client.put_file(path, invoice.inline_pdf, true)

    return if invoice.timers.present?

    path = (base_path + [
      "#{invoice.timesheet_file}.pdf"
    ]).join("/")
    client.put_file(path, invoice.inline_timesheet_pdf, true)
  end
end
