# encoding: utf-8
# frozen_string_literal: true

module ExpensesHelper
  def first_expenses_year
    first_invoice = current_account.invoices.order('date').first
    return if first_invoice.blank?
    first_invoice.date.year
  end

  def current_expenses_years
    current_year = Time.zone.now.year
    current_year = (Time.zone.now + 1.year).year if Time.zone.now.month == 12
    years = if first_expenses_year
              (first_expenses_year..current_year)
            else
              ((Time.zone.now - 1.year).year..current_year)
            end
    years.to_a.reverse.map do |year|
      { name: year, link: year }
    end
  end
end
