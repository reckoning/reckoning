# frozen_string_literal: true

module InvoicesHelper
  def invoice_label(invoice)
    case invoice.current_state.to_s
    when "created"
      "default"
    when "paid"
      "success"
    else
      "primary"
    end
  end

  def first_invoice_year
    first_invoice = current_account.invoices.order("date").first
    return if first_invoice.blank?

    first_invoice.date.year
  end
end
