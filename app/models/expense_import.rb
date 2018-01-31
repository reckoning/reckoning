# frozen_string_literal: true

class ExpenseImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :file, :account_id

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def save
    if imported_expenses.map(&:valid?).all?
      imported_expenses.each(&:save!)
      true
    else
      imported_expenses.each_with_index do |product, index|
        product.errors.full_messages.each do |message|
          errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      false
    end
  end

  def imported_expenses
    @imported_expenses ||= load_imported_expenses
  end

  def load_imported_expenses
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      expense = Expense.find_by(id: row["id"], account_id: account_id) || Expense.new(account_id: account_id)
      expense.attributes = row.to_hash.slice(*Expense.accessible_attributes)
      expense
    end
  end

  def open_spreadsheet
    case File.extname(file.original_filename)
    when ".csv" then Roo::CSV.new(file.path)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
