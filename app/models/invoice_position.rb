# frozen_string_literal: true

class InvoicePosition < Position
  has_many :timers, foreign_key: :position_id, dependent: :nullify, inverse_of: :position

  accepts_nested_attributes_for :timers

  def invoice
    invoicable
  end
end
