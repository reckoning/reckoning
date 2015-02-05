class Position < ActiveRecord::Base
  belongs_to :invoice, touch: true
  has_many :timers, dependent: :nullify

  before_save :set_value
  after_save :set_invoice_value

  validates :description, :invoice, presence: true

  accepts_nested_attributes_for :timers

  def set_value
    return if hours.blank? || hours.zero?
    if rate.present?
      self.value = hours * rate
    elsif invoice.rate.present?
      self.value = hours * invoice.rate
    else
      self.value = hours * invoice.project.rate
    end
  end

  def set_invoice_value
    invoice.set_value
    invoice.save
  end
end
