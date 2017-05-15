# encoding: utf-8
# frozen_string_literal: true

class ExpensePdf
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  include PdfOptions

  attr_accessor :account, :filter
  attr_accessor :telecommunication, :gwg
  attr_accessor :misc, :current, :licenses

  def initialize(account, expenses, filter)
    self.account = account
    self.filter = filter

    self.telecommunication = expenses.select { |expense| expense.expense_type == "telecommunication" }
    self.gwg = expenses.select { |expense| expense.expense_type == "gwg" }
    self.misc = expenses.select { |expense| expense.expense_type == "misc" }
    self.current = expenses.select { |expense| expense.expense_type == "current" }
    self.licenses = expenses.select { |expense| expense.expense_type == "licenses" }
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
