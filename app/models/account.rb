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
  store_accessor :services, :dropbox_user, :dropbox_token
  store_accessor :mailing, :default_from, :signature
  store_accessor :contact_information, :address, :country, :public_email, :telefon, :fax, :website

  validates :name, :users, :plan, presence: true
  # rubocop:disable Rails/UniqueValidationWithoutIndex empty subdomain prevents a unique index
  validates :subdomain, uniqueness: true, allow_blank: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :subdomain, exclusion: { in: %w[www app admin api backend reckoning] }
  validates_associated :users
  validates :stripe_token, :stripe_email, presence: true, on: :create, if: :on_paid_plan?

  accepts_nested_attributes_for :users

  before_save :calculate_office_percent
  before_create :set_trail_end_date

  def on_paid_plan?
    !on_plan?(:free)
  end

  def calculate_office_percent
    return if deductible_office_space.blank? || office_space.blank?

    self.deductible_office_percent = (100.0 * deductible_office_space / office_space).ceil
  end

  def set_trail_end_date
    return if on_plan?(:free)

    self.trail_used = true
    self.trail_end_at = 30.days.from_now
  end

  def provision_value
    return if provision.blank?

    current_invoices = invoices.includes(:customer, :project).order('date DESC').paid_in_year(Time.zone.now.year)
    current_expenses = expenses.without_insurances.year(Time.zone.now.year).to_a.sum(&:usable_value)
    open_afa_expenses = expenses.filter_type(:afa).reject do |expense|
      expense.afa_value(Time.zone.now.year).zero?
    end.sum do |expense|
      expense.afa_value(Time.zone.now.year)
    end
    (current_invoices.sum(:value) - current_expenses - open_afa_expenses) / 100 * provision.to_i
  end

  def last_provision_value
    return if provision.blank?

    last_invoices = invoices.includes(:customer, :project).order('date DESC').paid_in_year(Time.zone.now.year - 1)
    last_expenses = expenses.without_insurances.year(Time.zone.now.year - 1).to_a.sum(&:usable_value)
    open_afa_expenses = expenses.filter_type(:afa).reject do |expense|
      expense.afa_value(Time.zone.now.year - 1).zero?
    end.sum do |expense|
      expense.afa_value(Time.zone.now.year - 1)
    end
    (last_invoices.sum(:value) - last_expenses - open_afa_expenses) / 100 * provision.to_i
  end

  def dropbox?
    dropbox_token.present?
  end

  def on_plan?(on_plan)
    return if plan.blank?

    plan.to_sym == on_plan
  end
end
