# frozen_string_literal: true

class InvoiceMailer < ActionMailer::Base
  default from: Rails.application.secrets[:mailer_default_from].to_s

  attr_accessor :invoice

  def customer(invoice)
    self.invoice = invoice
    send_mail invoice.customer.invoice_email
  end

  def test(invoice, test_mail)
    self.invoice = invoice
    send_mail test_mail
  end

  private def send_mail(to)
    month = I18n.l(invoice.date, format: :month)
    date = I18n.l(invoice.date, format: :month_year)

    @body = invoice.customer.email_template
    @body = @body.gsub("{date}", date || '')
    @body = @body.gsub("{company}", invoice.customer.name || '')
    @body = @body.gsub("{project}", invoice.project.name || '')
    @body = @body.gsub("{month}", month || '')

    @signature = invoice.account.signature

    attachments["#{invoice.invoice_file}.pdf"] = invoice.inline_pdf
    attachments["#{invoice.timesheet_file}.pdf"] = invoice.inline_timesheet_pdf if invoice.timers.present?

    mail(
      from: from,
      to: to,
      subject: I18n.t(:"mailer.invoice.customer.subject", name: "#{invoice.account.name}: ", date: date),
      template_name: 'customer'
    )
  end

  private def from
    @from ||= invoice.customer.default_from if invoice.customer.default_from.present?
    @from ||= invoice.account.default_from if invoice.account.default_from.present?
    @from ||= Rails.application.secrets[:mailer_default_from].to_s
  end
end
