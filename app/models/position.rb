# frozen_string_literal: true

class Position < ApplicationRecord
  belongs_to :invoice, touch: true
  has_many :timers, dependent: :nullify

  before_save :set_value
  after_save :set_invoice_value

  validates :description, presence: true

  accepts_nested_attributes_for :timers

  def set_value
    return if hours.blank? || hours.zero?

    self.value = if rate.present?
                   hours * rate
                 elsif invoice.rate.present?
                   hours * invoice.rate
                 else
                   hours * invoice.project.rate
                 end
  end

  def set_invoice_value
    invoice.set_value
    invoice.save
  end
end
