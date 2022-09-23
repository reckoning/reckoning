# frozen_string_literal: true

require 'business_time'

class Project < ApplicationRecord
  DEFAULT_ROUND_UP_OPTIONS = {
    "Nicht aufrunden" => 0.minutes,
    "Auf 15 Minuten" => 15.minutes,
    "Auf 30 Minuten" => 30.minutes,
    "Auf 1 Stunde" => 60.minutes
  }.freeze

  belongs_to :customer
  has_many :invoices, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :tasks, dependent: :destroy, inverse_of: :project
  has_many :timers, through: :tasks

  validates :name, :rate, presence: true

  accepts_nested_attributes_for :tasks, allow_destroy: true

  delegate :name, to: :customer, prefix: true

  before_save :set_working_days

  include Workflow
  workflow do
    state :active do
      event :archive, transitions_to: :archived
    end
    state :archived do
      event :unarchive, transitions_to: :active
    end
  end

  def set_working_days
    return if start_date.blank? || end_date.blank?

    if federal_state.present?
      GermanHoliday.where(federal_state: ['NATIONAL', federal_state]).find_each do |holiday|
        BusinessTime::Config.holidays << holiday.date
      end
    end

    self.business_days = start_date.business_days_until(end_date)
  end

  def label
    name_with_customer
  end

  def self.active
    with_active_state
  end

  def self.archived
    with_archived_state
  end

  def self.with_budget
    where.not(budget: 0).where(budget_on_dashboard: true)
  end

  def name_with_customer
    "#{customer.name} - #{name}"
  end

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d if timer.value.present?
    end
    values
  end

  def timer_values_billable
    values = 0.0
    timers.billable.each do |timer|
      values += timer.value.to_d if timer.value.present?
    end
    values
  end

  def timer_values_invoiced
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d if timer.value.present? && timer.position_id.present?
    end
    values
  end

  def timer_values_uninvoiced
    values = 0.0
    timers.billable.each do |timer|
      values += timer.value.to_d if timer.value.present? && timer.position_id.blank?
    end
    values
  end

  def invoice_values
    values = 0.0
    invoices.each do |invoice|
      values += invoice.value.to_d
    end
    values
  end

  def budget_percent
    if budget_hours.present?
      timer_values / budget_hours * 100
    else
      invoice_values / budget * 100
    end
  end

  def budget_percent_invoiced
    return if budget_hours.blank?

    timer_values_invoiced / budget_hours * 100
  end

  def budget_percent_uninvoiced
    return if budget_hours.blank?

    timer_values_uninvoiced / budget_hours * 100
  end
end
