require 'dropbox_sdk'

class InvoiceDropboxAllWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['ARCHIVE_QUEUE'] || 'reckoning-archive-all').to_sym

  def perform user_id
    client = ::DropboxClient.new(invoice.user.dropbox_token)

    Invoice.where(user_id: user_id).each do |invoice|
      begin
        invoice.generate
        invoice.generate_timesheet if invoice.timers.present?

        invoice.update_attributes(pdf_generated_at: Time.now)

        InvoiceDropboxWorker.perform_async invoice.id
      rescue Exception => e
        Rails.logger.debug e.inspect
      ensure
        invoice.update_attributes(pdf_generating: false)
      end
    end
  end
end
