# frozen_string_literal: true

module InvoicesHelper
  def invoice_label(invoice)
    case invoice.current_state.to_s
    when 'created'
      'default'
    when 'paid'
      'success'
    else
      'primary'
    end
  end

  def first_invoice_year
    first_invoice = current_account.invoices.order('date').first
    return if first_invoice.blank?

    first_invoice.date.year
  end

  def current_invoice_years
    current_year = Time.zone.now.year
    current_year = 1.year.from_now.year if Time.zone.now.month == 12
    years = if first_invoice_year
              (first_invoice_year..current_year)
            else
              (1.year.ago.year..current_year)
            end
    years.to_a.reverse.map do |year|
      { name: year, link: year }
    end
  end
end
