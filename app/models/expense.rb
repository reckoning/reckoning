class Expense < ActiveRecord::Base
  belongs_to :account

  VALID_TYPES = %i(gwg afa misc).freeze

  mount_uploader :receipt, ReceiptUploader

  validates :value, :description, :date, :expense_type, :seller, presence: true

  def self.year(year)
    where("date <= ? AND date >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def self.filter(filter_params)
    filter_year(filter_params.fetch(:year, nil))
  end

  def self.filter_year(year)
    return all if year.blank? || !(year =~ /\d{4}/)
    year(year)
  end
end
