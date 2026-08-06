# frozen_string_literal: true

class ExpenseImport
  include ActiveModel::Model

  BANK_STATEMENT_HEADERS = %w[Date Name Purpose Amount Currency].freeze
  ROW_ATTRIBUTES = %w[
    id date started_at ended_at value vat_percent private_use_percent
    interval afa_type_id seller description expense_type
  ].freeze

  attr_accessor :file, :account_id, :expense_type, :vat_percent,
    :private_use_percent, :interval, :skip_credits, :rows

  def initialize(attributes = {})
    @expense_type = "current"
    @vat_percent = 19
    @private_use_percent = 0
    @interval = "once"
    @skip_credits = true
    super
  end

  def persisted?
    false
  end

  def skip_credits?
    boolean(skip_credits)
  end

  # Step 1 — parse the uploaded file into unsaved expenses for the preview table.
  def preview_expenses
    return [] if file.blank?

    @preview_expenses ||= parse_file
  end

  # Step 2 — persist the (edited, selected) rows submitted from the preview.
  def save
    if selected_expenses.empty?
      errors.add(:base, I18n.t(:"expenses.import.no_rows_selected"))
      return false
    end

    if selected_expenses.map(&:valid?).all?
      selected_expenses.each(&:save!)
      true
    else
      selected_expenses.each_with_index do |expense, index|
        expense.errors.full_messages.each do |message|
          errors.add :base, I18n.t(:"expenses.import.row_error", row: index + 1, message: message)
        end
      end
      false
    end
  end

  def selected_expenses
    @selected_expenses ||= normalized_rows
      .select { |row| boolean(row[:include]) }
      .map { |row| build_from_row(row) }
  end

  private

  def parse_file
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    rows = (2..spreadsheet.last_row).map do |i|
      [header, spreadsheet.row(i)].transpose.to_h
    end

    if bank_statement?(header)
      rows.filter_map { |row| build_bank_expense(row) }
    else
      rows.map { |row| build_reckoning_expense(row) }
    end
  end

  def bank_statement?(header)
    (BANK_STATEMENT_HEADERS - header.map(&:to_s)).empty?
  end

  def build_reckoning_expense(row)
    expense = Expense.find_by(id: row["id"], account_id: account_id) || Expense.new(account_id: account_id)
    expense.attributes = row.slice(*Expense.accessible_attributes)
    expense
  end

  def build_bank_expense(row)
    amount = parse_amount(row["Amount"])
    return nil if amount.nil?
    return nil if skip_credits? && amount.positive?

    seller = row["Name"].to_s.strip
    Expense.new(
      account_id: account_id,
      date: parse_date(row["Date"]),
      seller: seller.presence,
      description: row["Purpose"].to_s.strip.presence || seller.presence,
      value: amount.abs,
      expense_type: expense_type,
      vat_percent: vat_percent,
      private_use_percent: private_use_percent,
      interval: interval
    )
  end

  def build_from_row(row)
    attributes = row.slice(*ROW_ATTRIBUTES)
    expense = Expense.find_by(id: attributes[:id].presence, account_id: account_id) || Expense.new(account_id: account_id)
    expense.assign_attributes(attributes.except(:id))
    expense
  end

  def normalized_rows
    Array(rows).map { |row| row.to_h.with_indifferent_access }
  end

  def parse_amount(value)
    return value if value.is_a?(Numeric)
    return nil if value.blank?

    Float(value.to_s.strip.delete(".").tr(",", "."))
  rescue ArgumentError
    nil
  end

  def parse_date(value)
    return value if value.is_a?(Date)

    Date.strptime(value.to_s.strip, "%d.%m.%Y")
  rescue ArgumentError, TypeError
    nil
  end

  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def open_spreadsheet
    case File.extname(file.original_filename).downcase
    when ".csv" then Roo::CSV.new(file.path, csv_options: {col_sep: column_separator})
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def column_separator
    first_line = File.open(file.path, &:gets).to_s
    (first_line.count(";") > first_line.count(",")) ? ";" : ","
  end
end
