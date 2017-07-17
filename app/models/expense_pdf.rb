# encoding: utf-8
# frozen_string_literal: true

class ExpensePdf
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  include PdfOptions

  attr_accessor :account, :filter
  attr_accessor :telecommunication, :home_office, :gwg, :travel_costs, :business_expenses, :training
  attr_accessor :misc, :current, :licenses, :non_cash_contribution, :insurances

  def initialize(account, expenses, filter)
    self.account = account
    self.filter = filter

    self.telecommunication = expenses.select { |expense| expense.expense_type == 'telecommunication' }.sort_by(&:date)
    self.home_office = expenses.select { |expense| expense.expense_type == 'home_office' }.sort_by(&:date)
    self.gwg = expenses.select { |expense| expense.expense_type == 'gwg' }.sort_by(&:date)
    self.misc = expenses.select { |expense| expense.expense_type == 'misc' }.sort_by(&:date)
    self.current = expenses.select { |expense| expense.expense_type == 'current' }.sort_by(&:date)
    self.licenses = expenses.select { |expense| expense.expense_type == 'licenses' }.sort_by(&:date)
    self.travel_costs = expenses.select { |expense| expense.expense_type == 'travel_costs' }.sort_by(&:date)
    self.business_expenses = expenses.select { |expense| expense.expense_type == 'business_expenses' }.sort_by(&:date)
    self.training = expenses.select { |expense| expense.expense_type == 'training' }.sort_by(&:date)
    self.non_cash_contribution = expenses.select { |expense| expense.expense_type == 'non_cash_contribution' }.sort_by(&:date)
    self.insurances = expenses.select { |expense| expense.expense_type == 'insurances' }.sort_by(&:date)
  end

  def persisted?
    false
  end

  def pdf
    pdf_options(pdf_file)
  end

  def pdf_file
    year = filter.fetch(:year, Time.zone.now.year)
    type = filter.fetch(:type, '')
    if type.present?
      "expenses-#{year}-#{type}"
    else
      "expenses-#{year}"
    end
  end
end
