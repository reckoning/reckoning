# frozen_string_literal: true

class Expense < ApplicationRecord
  belongs_to :account

  VALID_TYPES = %i[
    gwg afa licenses telecommunication training business_expenses
    work_related_deductions home_office current misc
    travel_costs non_cash_contribution business_insurances insurances
  ].freeze
  # TODO: needs to be complete AFA Table
  VALID_AFA_TYPES = [{
    value: 3,
    label: I18n.t(:'expenses.afa_types.computer')
  }, {
    value: 5,
    label: I18n.t(:'expenses.afa_types.smartphone')
  }, {
    value: 7,
    label: I18n.t(:'expenses.afa_types.tv')
  }, {
    value: 13,
    label: I18n.t(:'expenses.afa_types.office_furniture')
  }].freeze
  BUSINESS_TYPES = %i[home_office telecommunication current business_expenses non_cash_contribution insurances].freeze
  NEEDS_RECEIPT_TYPES = VALID_TYPES.reject do |type|
    BUSINESS_TYPES.include?(type)
  end.freeze

  attachment :receipt, content_type: ['application/pdf', 'image/jpeg', 'image/png']

  validates :value, :description, :date, :expense_type, :seller, :private_use_percent, presence: true
  validates :afa_type, presence: true, if: ->(expense) { expense.expense_type == 'afa' }

  def self.accessible_attributes
    %w[description seller value usable_value private_use_percent created_at updated_at date expense_type afa_type]
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.find_each do |expense|
        csv << expense.attributes.values_at(*column_names)
      end
    end
  end

  def self.year(year)
    where('extract(year  from date) = ?', year)
  end

  def self.month(month)
    where('extract(month from date) = ?', month)
  end

  def self.months(months)
    where('extract(month from date) IN (?)', months)
  end

  def self.without_insurances
    where.not(expense_type: 'insurances')
  end

  def self.filter_result(filter_params)
    filter_year(filter_params.fetch(:year, nil))
      .filter_month(filter_params.fetch(:month, nil))
      .filter_quarter(filter_params.fetch(:quarter, nil))
      .filter_type(filter_params.fetch(:type, nil))
  end

  def self.filter_year(year)
    return all if year.blank? || year !~ /\d{4}/

    year(year)
  end

  def self.filter_month(month)
    return all if month.blank? || !I18n.t('date.month_names').index(month)

    month(I18n.t('date.month_names').index(month))
  end

  def self.filter_quarter(quarter)
    return all unless (1..4).cover?(quarter.to_i)

    months(quarters[quarter.to_i - 1])
  end

  def self.quarters
    [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]
  end

  def self.filter_type(type)
    return all if type.blank? || VALID_TYPES.exclude?(type.to_sym)

    where(expense_type: type)
  end

  def afa_value(year = Time.zone.now.year)
    return 0.0 if afa_type.blank? || (date.year + afa_type) < year

    value / afa_type
  end

  def home_office_value
    return if account.deductible_office_percent.blank?

    (value * account.deductible_office_percent) / 100.0
  end

  def deductible_value
    (value * (100 - private_use_percent).to_f) / 100.0
  end

  def usable_value(year = Time.zone.now.year)
    case expense_type
    when 'afa'
      afa_value(year)
    when 'home_office'
      home_office_value
    else
      deductible_value
    end
  end

  def value_without_vat
    return usable_value if vat_percent.zero?

    (usable_value * 100) / (100 + vat_percent)
  end

  def vat_value
    if expense_type == 'afa'
      value * vat_percent / 100
    else
      usable_value * vat_percent / 100
    end
  end

  def needs_receipt?
    NEEDS_RECEIPT_TYPES.include?(expense_type.to_sym)
  end

  def to_prefill_params
    {
      value: value,
      description: description,
      date: date,
      expense_type: expense_type,
      seller: seller,
      private_use_percent: private_use_percent,
      vat_percent: vat_percent
    }
  end
end
