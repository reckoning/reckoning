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

  def expenses_months
    I18n.t("date.month_names").compact.map do |month|
      { name: month, link: month }
    end
  end

  def expenses_quarters
    (1..4).map do |quarter|
      { name: quarter, link: quarter }
    end
  end
end
