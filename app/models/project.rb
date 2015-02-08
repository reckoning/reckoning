class Project < ActiveRecord::Base
  belongs_to :customer
  has_many :invoices, dependent: :destroy
  has_many :tasks, dependent: :destroy, inverse_of: :project
  has_many :timers, through: :tasks

  validates :customer_id, :name, :rate, presence: true

  accepts_nested_attributes_for :tasks, allow_destroy: true

  include ::SimpleStates

  self.initial_state = :active
  # active -> archive -> active
  states :active, :archived

  event :archive, from: :active, to: :archived
  event :unarchive, from: :archived, to: :active

  def self.active
    where(state: :active)
  end

  def self.archived
    where(state: :archived)
  end

  def self.with_budget
    where("budget != ?", 0).where(budget_on_dashboard: true)
  end

  def name_with_customer
    "#{customer.name} - #{name}"
  end

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d unless timer.value.blank?
    end
    values
  end

  def timer_values_invoiced
    values = 0.0
    timers.each do |timer|
      if timer.value.present? && timer.position_id.present?
        values += timer.value.to_d
      end
    end
    values
  end

  def timer_values_uninvoiced
    values = 0.0
    timers.each do |timer|
      if timer.value.present? && timer.position_id.blank?
        values += timer.value.to_d
      end
    end
    values
  end

  def budget_percent
    timer_values / budget * 100
  end

  def budget_percent_invoiced
    timer_values_invoiced / budget * 100
  end

  def budget_percent_uninvoiced
    timer_values_uninvoiced / budget * 100
  end
end
