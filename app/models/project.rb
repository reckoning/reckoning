class Project < ActiveRecord::Base
  validates_presence_of :customer_id, :name, :rate

  belongs_to :customer
  has_many :invoices
  has_many :tasks
  has_many :timers, through: :tasks

  accepts_nested_attributes_for :tasks, allow_destroy: true

  def name_with_customer
    "#{self.customer.fullname} - #{self.name}"
  end

end
