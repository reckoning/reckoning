# encoding: utf-8
class InvoiceMailer < ActionMailer::Base
  default from: "#{Settings.mailer.default_from}"

  def customer_mail invoice
    month = I18n.l(invoice.date, format: :month)
    date = I18n.l(invoice.date, format: :month_year)

    @body = invoice.customer.email_template
    @body = @body.gsub("{date}", date || '')
    @body = @body.gsub("{company}", invoice.customer.name || '')
    @body = @body.gsub("{month}", month || '')

    @signature = invoice.user.signature

    attachments[invoice.invoice_file] = File.read(invoice.pdf_path)
    if File.exists?(invoice.timesheet_path)
      attachments[invoice.timesheet_file] = File.read(invoice.timesheet_path)
    end

    name = invoice.user.name
    if invoice.user.company.present?
      name = invoice.user.company
    end

    mail(
      from: (invoice.customer.default_from || invoice.user.default_from || Settings.mailer.default_from),
      to: invoice.customer.invoice_email,
      bcc: invoice.user.email,
      subject: I18n.t(:"mailer.invoice.customer_mail.subject", name: "#{name}: ", date: date)
    )
  end
end
