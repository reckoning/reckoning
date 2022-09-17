# frozen_string_literal: true

class ExpensePdf
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  include PdfOptions

  attr_accessor :account, :filter, :telecommunication, :home_office, :gwg, :travel_costs, :business_expenses, :training, :misc, :current, :licenses, :non_cash_contribution, :insurances

  # rubocop:disable Metrics/CyclomaticComplexity
  def initialize(account, expenses, filter)
    self.account = account
    self.filter = filter

    normalized_expenses = Expense.normalized(expenses, year_filter: year_filter)

    self.telecommunication = normalized_expenses.select { |expense| expense.expense_type == 'telecommunication' }.sort_by(&:date)
    self.home_office = normalized_expenses.select { |expense| expense.expense_type == 'home_office' }.sort_by(&:date)
    self.gwg = normalized_expenses.select { |expense| expense.expense_type == 'gwg' }.sort_by(&:date)
    self.misc = normalized_expenses.select { |expense| expense.expense_type == 'misc' }.sort_by(&:date)
    self.current = normalized_expenses.select { |expense| expense.expense_type == 'current' }.sort_by(&:date)
    self.licenses = normalized_expenses.select { |expense| expense.expense_type == 'licenses' }.sort_by(&:date)
    self.travel_costs = normalized_expenses.select { |expense| expense.expense_type == 'travel_costs' }.sort_by(&:date)
    self.business_expenses = normalized_expenses.select { |expense| expense.expense_type == 'business_expenses' }.sort_by(&:date)
    self.training = normalized_expenses.select { |expense| expense.expense_type == 'training' }.sort_by(&:date)
    self.non_cash_contribution = normalized_expenses.select { |expense| expense.expense_type == 'non_cash_contribution' }.sort_by(&:date)
    self.insurances = normalized_expenses.select { |expense| expense.expense_type == 'insurances' }.sort_by(&:date)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def persisted?
    false
  end

  def pdf
    pdf_options(pdf_file)
  end

  def year_filter
    filter.fetch(:year, nil)
  end

  def pdf_file
    year = year_filter || Time.zone.now.year
    type = filter.fetch(:type, '')
    if type.present?
      "expenses-#{year}-#{type}"
    else
      "expenses-#{year}"
    end
  end
end
