# frozen_string_literal: true

class Position < ApplicationRecord
  belongs_to :invoicable, polymorphic: true, touch: true

  before_save :set_value
  after_save :set_invoicable_value

  validates :description, presence: true

  def set_value
    return if hours.blank? || hours.zero?

    self.value = if rate.present?
      hours * rate
    elsif invoicable.rate.present?
      hours * invoicable.rate
    else
      hours * invoicable.project.rate
    end
  end

  def set_invoicable_value
    invoicable.set_value
    invoicable.save
  end
end
