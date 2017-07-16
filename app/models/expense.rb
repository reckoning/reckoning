# encoding: utf-8
# frozen_string_literal: true

class Expense < ApplicationRecord
  belongs_to :account

  VALID_TYPES = %i[gwg afa licenses telecommunication work_related_deductions home_office current misc].freeze
  NEEDS_RECEIPT_TYPES = VALID_TYPES.reject { |type| %i[telecommunication current].include?(type) }.freeze

  attachment :receipt, content_type: ["application/pdf", "image/jpeg", "image/png"]

  validates :value, :description, :date, :expense_type, :seller, :private_use_percent, presence: true

  before_save :calculate_usable_value

  def self.accessible_attributes
    %w[description seller value usable_value private_use_percent created_at updated_at date expense_type]
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
    where("date <= ? AND date >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def self.filter(filter_params)
    filter_year(filter_params.fetch(:year, nil))
      .filter_type(filter_params.fetch(:type, nil))
  end

  def self.filter_year(year)
    return all if year.blank? || year !~ /\d{4}/
    year(year)
  end

  def self.filter_type(type)
    return all if type.blank? || !VALID_TYPES.include?(type.to_sym)
    where(expense_type: type)
  end

  def calculate_usable_value
    self.usable_value = (value * (100 - private_use_percent).to_f) / 100.0
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
      private_use_percent: private_use_percent
    }
  end
end
