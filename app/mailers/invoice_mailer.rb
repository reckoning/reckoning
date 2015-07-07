# encoding: utf-8
class InvoiceMailer < ActionMailer::Base
  default from: "#{Rails.application.secrets[:mailer]['default_from']}"

  attr_accessor :invoice

  def customer_mail(invoice)
    self.invoice = invoice
    send_mail invoice.customer.invoice_email
  end

  def test_mail(invoice, test_mail)
    self.invoice = invoice
    send_mail test_mail
  end

  private

  def send_mail(to)
    month = I18n.l(invoice.date, format: :month)
    date = I18n.l(invoice.date, format: :month_year)

    @body = invoice.customer.email_template
    @body = @body.gsub("{date}", date || '')
    @body = @body.gsub("{company}", invoice.customer.name || '')
    @body = @body.gsub("{month}", month || '')

    @signature = invoice.account.signature

    invoice_pdf_path(invoice, invoice.invoice_file)

    attachments[invoice.invoice_file] = invoice.inline_pdf
    attachments[invoice.timesheet_file] = invoice.inline_timesheet_pdf unless invoice.timers.blank?

    mail(
      from: from,
      to: to,
      subject: I18n.t(:"mailer.invoice.customer_mail.subject", name: "#{invoice.account.name}: ", date: date),
      template_name: 'customer_mail'
    )
  end

  def from
    @from ||= invoice.customer.default_from if invoice.customer.default_from.present?
    @from ||= invoice.account.default_from if invoice.account.default_from.present?
    @from ||= Rails.application.secrets[:mailer]["default_from"]
  end
end
