# frozen_string_literal: true

class Expense < ApplicationRecord
  belongs_to :account
  belongs_to :afa_type, optional: true

  VALID_TYPES = %i[
    gwg afa licenses telecommunication training business_expenses
    work_related_deductions home_office current misc
    travel_costs non_cash_contribution business_insurances insurances
  ].freeze
  BUSINESS_TYPES = %i[home_office telecommunication current business_expenses non_cash_contribution insurances].freeze
  NEEDS_RECEIPT_TYPES = VALID_TYPES.reject do |type|
    BUSINESS_TYPES.include?(type)
  end.freeze

  enum interval: {once: 0, weekly: 1, monthly: 2, quarterly: 3, yearly: 4}

  has_one_attached :receipt

  validates :receipt, content_type: ["application/pdf", "image/jpeg", "image/png"]

  validates :value, :description, :expense_type, :seller, :private_use_percent, :interval, presence: true
  validates :afa_type, presence: true, if: ->(expense) { expense.expense_type == "afa" }

  validates :date, presence: true, if: ->(expense) { expense.once? }
  validates :started_at, presence: true, unless: ->(expense) { expense.once? }
  validate :ended_at_is_after_started_at

  delegate :value, to: :afa_type, prefix: true, allow_nil: true

  def self.accessible_attributes
    %w[
      description seller value usable_value private_use_percent created_at updated_at date
      expense_type afa_type_value vat_percent interval started_at ended_at
    ]
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
    where(interval: :once).where("extract(year from date) = ?", year)
      .or(
        Expense.where.not(interval: :once)
          .where("extract(year from started_at) <= :year AND (ended_at IS NULL OR extract(year from ended_at) >= :year)", year: year)
      )
  end

  def self.date_range(start_date:, end_date: nil)
    where(interval: :once, date: start_date..end_date)
      .or(
        Expense.where.not(interval: :once)
          .where(
            "started_at <= :end_date AND (ended_at IS NULL OR ended_at >= :start_date)",
            start_date: start_date,
            end_date: end_date
          )
      )
  end

  def self.without_insurances
    where.not(expense_type: "insurances")
  end

  def self.without_afa
    where.not(expense_type: "afa")
  end

  def self.filter_result(filter_params)
    filter_year(filter_params.fetch(:year, nil))
      .filter_quarter(filter_params.fetch(:quarter, nil), filter_params.fetch(:year, Time.current.year))
      .filter_month(filter_params.fetch(:month, nil), filter_params.fetch(:year, Time.current.year))
      .filter_date_range(
        start_date: filter_params.fetch(:start_date, nil),
        end_date: filter_params.fetch(:end_date, nil)
      )
      .filter_type(filter_params.fetch(:type, nil))
      .filter_search(filter_params.fetch(:query, nil))
  end

  def self.filter_year(year)
    return all if year.blank? || year !~ /\d{4}/

    year(year)
  end

  def self.filter_quarter(quarter, year = Time.current.year)
    return all if quarter.blank? || !(1..4).cover?(quarter.to_i)

    date_range(
      start_date: Date.new(year.to_i, quarter.to_i * 3 - 2, 1),
      end_date: Date.new(year.to_i, quarter.to_i * 3 + 1, -1)
    )
  end

  def self.filter_month(month, year = Time.current.year)
    return all if month.blank? || !(1..12).cover?(month.to_i)

    date_range(
      start_date: Date.new(year.to_i, month.to_i, 1),
      end_date: Date.new(year.to_i, month.to_i, -1)
    )
  end

  def self.filter_date_range(start_date: nil, end_date: nil)
    return all if start_date.blank?

    date_range(start_date: start_date, end_date: end_date)
  end

  def self.filter_type(type)
    return all if type.blank? || VALID_TYPES.exclude?(type.to_sym)

    where(expense_type: type)
  end

  def self.filter_search(query)
    return all if query.blank?

    where("description ILIKE ?", "%#{query}%")
  end

  def self.normalized(expenses, year: nil)
    expenses.map do |expense|
      if expense.once?
        expense
      else
        expense.dates_for_interval.filter_map do |date|
          next if year.present? && date.year != year.to_i

          new_expense = expense.dup
          new_expense.date = date
          new_expense
        end
      end
    end.flatten
  end

  def ended_at_is_after_started_at
    errors.add(:ended_at, "cannot be before the start date") if ended_at.present? && ended_at < started_at
  end

  def dates_for_interval
    return [] if once?

    dates = []
    end_date = ended_at || Time.current
    current_date = started_at
    index = 1
    while current_date <= end_date
      dates << current_date
      current_date = started_at.advance(timerange_for_interval(index))
      index += 1
    end

    dates
  end

  def timerange_for_interval(index = 1)
    case interval
    when "weekly"
      {weeks: index}
    when "monthly"
      {months: index}
    when "quarterly"
      {months: index * 3}
    when "yearly"
      {years: index}
    end
  end

  def afa_value(year = Time.zone.now.year)
    return 0.0 if afa_type_value.blank? || (date.year + afa_type_value) < year

    value / afa_type_value
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
    when "afa"
      afa_value(year)
    when "home_office"
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
    if expense_type == "afa"
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
      vat_percent: vat_percent,
      afa_type_id: afa_type_id,
      interval: interval,
      started_at: started_at,
      ended_at: ended_at
    }
  end
end
