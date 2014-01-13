class Position < ActiveRecord::Base
  belongs_to :invoice, touch: true

  before_save :set_value
  after_save :set_invoice_value

  validates_presence_of :description, :invoice

  def set_value
    if self.hours.present? && !self.hours.zero?
      if rate.present?
        self.value = self.hours * rate
      elsif self.invoice.rate.present?
        self.value = self.hours * self.invoice.rate
      else
        self.value = self.hours * self.invoice.project.rate
      end
    end
  end

  def set_invoice_value
    self.invoice.set_value
    self.invoice.save
  end

end
