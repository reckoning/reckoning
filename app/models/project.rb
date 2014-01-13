class Project < ActiveRecord::Base
  validates_presence_of :customer_id, :name, :rate

  belongs_to :customer
  has_many :invoices

  def name_with_customer
    "#{self.customer.fullname} - #{self.name}"
  end

end
