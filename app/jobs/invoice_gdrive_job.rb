# encoding: utf-8
class InvoiceGdriveJob
  @queue = (ENV['ARCHIVE_QUEUE'] || '').to_sym

  def self.perform invoice_id
    invoice = Invoice.find invoice_id

    if invoice.present?
      session = GoogleDrive.login(invoice.user.gdrive_email, invoice.user.gdrive_password)

      collection = session.collection_by_title(invoice.user.gdrive_collection)
      if collection.blank?
        collection = session.root_collection.create_subcollection(invoice.user.gdrive_collection)
      end

      customer_collection = collection.subcollection_by_title(invoice.customer.fullname)
      if customer_collection.blank?
        customer_collection = collection.create_subcollection(invoice.customer.fullname)
      end

      invoice_file = customer_collection.files(title: invoice.invoice_file)
      if invoice_file.present?
        invoice_file.first.delete(true)
      end
      invoice_file = session.upload_from_file(invoice.pdf_path, invoice.invoice_file, convert: false)

      customer_collection.add invoice_file
      session.root_collection.remove invoice_file

      if File.exists?(invoice.timesheet_path)
        timesheet_file = customer_collection.files(title: invoice.timesheet_file)
        if timesheet_file.present?
          timesheet_file.first.delete(true)
        end

        timesheet_file = session.upload_from_file(invoice.timesheet_path, invoice.timesheet_file, convert: false)

        customer_collection.add timesheet_file
        session.root_collection.remove timesheet_file
      end
    end
  end
end
