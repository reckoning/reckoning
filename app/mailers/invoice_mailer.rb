# encoding: utf-8
class InvoiceMailer < ActionMailer::Base
  default from: "#{Rails.application.secrets[:mailer]["default_from"]}"

  attr_accessor :invoice

  def customer_mail invoice
    self.invoice = invoice
    send_mail invoice.customer.invoice_email
  end

  def test_mail invoice, test_mail
    self.invoice = invoice
    send_mail test_mail
  end

  private

  def send_mail to
    month = I18n.l(invoice.date, format: :month)
    date = I18n.l(invoice.date, format: :month_year)

    @body = invoice.customer.email_template
    @body = @body.gsub("{date}", date || '')
    @body = @body.gsub("{company}", invoice.customer.name || '')
    @body = @body.gsub("{month}", month || '')

    @signature = invoice.user.signature

    attachments[invoice.invoice_file] = File.read(invoice.pdf_path)
    attachments[invoice.timesheet_file] = File.read(invoice.timesheet_path) if File.exists?(invoice.timesheet_path)

    name = invoice.user.name
    if invoice.user.company.present?
      name = invoice.user.company
    end

    mail(
      from: from,
      to: to,
      subject: I18n.t(:"mailer.invoice.customer_mail.subject", name: "#{name}: ", date: date),
      template_name: 'customer_mail'
    )
  end

  def from
    @from ||= invoice.customer.default_from if invoice.customer.default_from.present?
    @from ||= invoice.user.default_from if invoice.user.default_from.present?
    @from ||= Rails.application.secrets[:mailer]["default_from"]
  end
end
