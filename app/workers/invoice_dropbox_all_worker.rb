# frozen_string_literal: true

require "dropbox_sdk"

class InvoiceDropboxAllWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV["ARCHIVE_QUEUE"] || "reckoning-archive-all").to_sym

  def perform(account_id)
    Invoice.where(account_id: account_id).each do |invoice|
      invoice.generate
      invoice.generate_timesheet if invoice.timers.present?

      invoice.update(pdf_generated_at: Time.zone.now)

      InvoiceDropboxWorker.perform_async invoice.id
    rescue => e
      Rails.logger.debug e.inspect
    ensure
      invoice.update(pdf_generating: false)
    end
  end
end
