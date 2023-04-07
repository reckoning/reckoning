# frozen_string_literal: true

class TaxRate < ApplicationRecord
  belongs_to :account

  validates :value, :valid_from, presence: true

  def self.current
    where("valid_from <= :now AND (valid_until IS NULL OR valid_until >= :now)", now: Time.current)
      .order(valid_from: :desc)
      .first
  end

  def self.valid_on(datetime:)
    where("valid_from <= :time AND (valid_until IS NULL OR valid_until >= :time)", time: datetime)
      .order(valid_from: :desc)
      .first
  end

  def self.current_or_valid_on(datetime: nil)
    current || valid_on(datetime: datetime)
  end
end
