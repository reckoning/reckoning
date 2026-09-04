# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :tax_rates, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :projects, through: :customers
  has_many :tasks, through: :projects
  has_many :timers, through: :tasks
  has_many :expenses, dependent: :destroy

  store_accessor :settings, :tax, :provision
  store_accessor :bank_account, :bank, :account_number, :bank_code, :iban, :bic
  store_accessor :mailing, :default_from, :signature
  store_accessor :contact_information, :address, :country, :public_email, :telefon, :fax, :website

  validates :name, :users, :plan, presence: true
  # rubocop:disable Rails/UniqueValidationWithoutIndex -- empty subdomain prevents a unique index
  validates :subdomain, uniqueness: true, allow_blank: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :subdomain, exclusion: {in: %w[www app admin api backend reckoning]}
  validates_associated :users

  accepts_nested_attributes_for :users

  before_save :calculate_office_percent
  before_create :start_trial

  def uninvoiced_amount
    projects.active.where("rate IS NOT NULL AND rate > 0").sum do |project|
      project.timer_values_uninvoiced * project.rate
    end + invoices.includes(:customer, :project).order("date DESC").created.sum(:value)
  end

  def on_paid_plan?
    !on_plan?(:free)
  end

  def calculate_office_percent
    return if deductible_office_space.blank? || office_space.blank?

    self.deductible_office_percent = (100.0 * deductible_office_space / office_space).ceil
  end

  # Signing up costs nothing and asks for no card, so every new account gets
  # the same fortnight. `Ability` turns read-only when it runs out.
  TRIAL_LENGTH = 14.days

  def start_trial
    return if on_plan?(:free)

    self.trial_used = true
    self.trial_end_at = TRIAL_LENGTH.from_now
  end

  def trial?
    trial_end_at.present?
  end

  def trial_active?
    trial? && trial_end_at.future?
  end

  def trial_expired?
    trial? && trial_end_at.past?
  end

  # Counted in whole days, rounded up: with eight hours left a banner saying
  # "0 days" is worse than useless.
  def trial_days_left
    return 0 unless trial_active?

    ((trial_end_at - Time.current) / 1.day).ceil
  end

  def provision_value
    return if provision.blank?

    current_invoices = invoices.includes(:customer, :project).order("date DESC").paid_in_year(Time.zone.now.year)

    current_expenses = Expense.normalized(
      expenses.without_insurances.without_afa.year(Time.zone.now.year).to_a,
      year: Time.zone.now.year
    ).sum do |expense|
      expense.usable_value(Time.zone.now.year)
    end

    open_afa_expenses = expenses.filter_type(:afa).sum do |expense|
      expense.afa_value(Time.zone.now.year)
    end

    (current_invoices.sum(:value) - current_expenses - open_afa_expenses) / 100 * provision.to_i
  end

  def last_provision_value
    return if provision.blank?

    last_invoices = invoices.includes(:customer, :project).order("date DESC").paid_in_year(Time.zone.now.year - 1)
    last_expenses = expenses.without_insurances.year(Time.zone.now.year - 1).to_a.sum do |expense|
      expense.usable_value(Time.zone.now.year - 1)
    end
    open_afa_expenses = expenses.filter_type(:afa).reject do |expense|
      expense.afa_value(Time.zone.now.year - 1).zero?
    end.sum do |expense|
      expense.afa_value(Time.zone.now.year - 1)
    end
    (last_invoices.sum(:value) - last_expenses - open_afa_expenses) / 100 * provision.to_i
  end

  def on_plan?(on_plan)
    return if plan.blank?

    plan.to_sym == on_plan
  end
end
