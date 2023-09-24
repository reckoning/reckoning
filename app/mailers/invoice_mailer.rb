# frozen_string_literal: true

class InvoiceMailer < ApplicationMailer
  attr_accessor :invoice

  def customer(invoice)
    self.invoice = invoice
    send_mail(
      invoice.customer.invoice_email&.split(","),
      invoice.customer.invoice_email_cc&.split(","),
      invoice.customer.invoice_email_bcc&.split(",")
    )
  end

  def test(invoice, test_mail)
    self.invoice = invoice
    send_mail(test_mail)
  end

  private def send_mail(to, cc = [], bcc = [])
    month = I18n.l(invoice.date, format: :month)
    date = I18n.l(invoice.date, format: :month_year)

    @body = invoice.customer.email_template
    @body = @body.gsub("{date}", date || "")
    @body = @body.gsub("{company}", invoice.customer.name || "")
    @body = @body.gsub("{project}", invoice.project.name || "")
    @body = @body.gsub("{month}", month || "")

    @signature = invoice.account.signature

    attachments["#{invoice.invoice_file}.pdf"] = invoice.inline_pdf
    attachments["#{invoice.timesheet_file}.pdf"] = invoice.inline_timesheet_pdf if invoice.timers.present?

    cc = (cc || []) + [invoice.account.contact_information["public_email"]]
    bcc = (bcc || []) + invoice.account.users.pluck(:email) if invoice.account.contact_information["public_email"].blank?

    mail(
      to: to,
      cc: cc&.compact,
      bcc: bcc&.compact,
      subject: I18n.t(:"mailer.invoice.customer.subject", name: "#{invoice.account.name}: ", date: date),
      template_name: "customer"
    )
  end
end
