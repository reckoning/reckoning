# encoding: utf-8
class InvoiceGdriveJob
  @queue = (ENV['ARCHIVE_QUEUE'] || '').to_sym

  def self.perform invoice_id
    invoice = Invoice.find invoice_id

    if invoice.present?
      session = GoogleDrive.login(invoice.user.gdrive_email, invoice.user.gdrive_password)

      collection = build_collection_path(invoice, session)

      invoice_file = collection.files(title: invoice.invoice_file)
      if invoice_file.present?
        invoice_file.first.delete(true)
      end
      invoice_file = session.upload_from_file(invoice.pdf_path, invoice.invoice_file, convert: false)

      collection.add invoice_file
      session.root_collection.remove invoice_file

      if File.exists?(invoice.timesheet_path)
        timesheet_file = customer_collection.files(title: invoice.timesheet_file)
        if timesheet_file.present?
          timesheet_file.first.delete(true)
        end

        timesheet_file = session.upload_from_file(invoice.timesheet_path, invoice.timesheet_file, convert: false)

        collection.add timesheet_file
        session.root_collection.remove timesheet_file
      end
    end
  end

  protected

  def self.build_collection_path invoice, session
    default_collection = Settings.app.gdrive_collection
    default_collection = invoice.user.gdrive_collection unless invoice.user.gdrive_collection.blank?

    start_collection = session.collection_by_title(default_collection)

    if start_collection.blank?
      start_collection = session.root_collection.create_subcollection(default_collection)
    end

    year_collection = start_collection.subcollection_by_title(invoice.date.year)
    if year_collection.blank?
      year_collection = start_collection.create_subcollection(invoice.date.year)
    end

    customer_collection = year_collection.subcollection_by_title(invoice.customer.fullname)
    if customer_collection.blank?
      customer_collection = year_collection.create_subcollection(invoice.customer.fullname)
    end

    project_collection = customer_collection.subcollection_by_title(invoice.project.name)
    if project_collection.blank?
      project_collection = customer_collection.create_subcollection(invoice.project.name)
    end

    return project_collection
  end
end
