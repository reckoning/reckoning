# frozen_string_literal: true

module ExpensesHelper
  def first_expenses_year
    first_invoice = current_account.invoices.order("date").first
    return if first_invoice.blank?

    first_invoice.date.year
  end

  def current_expenses_years
    current_year = Time.zone.now.year
    current_year = 1.year.from_now.year if Time.zone.now.month == 12
    years = if first_expenses_year
      (first_expenses_year..current_year)
    else
      (1.year.ago.year..current_year)
    end
    years.to_a.reverse.map do |year|
      {name: year, link: year}
    end
  end
end
