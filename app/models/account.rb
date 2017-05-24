# encoding: utf-8
# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :positions, through: :invoices
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
  validates :subdomain, uniqueness: true, allow_blank: true
  validates :subdomain, exclusion: { in: %w[www app admin api backend reckoning] }
  validates_associated :users
  validates :stripe_token, :stripe_email, presence: true, on: :create, if: :on_paid_plan?
  validates :vat_id, valvat: { lookup: :fail_if_down, allow_blank: true }

  accepts_nested_attributes_for :users

  before_create :set_trail_end_date

  def on_paid_plan?
    !on_plan?(:free)
  end

  def set_trail_end_date
    return if on_plan?(:free)

    self.trail_used = true
    self.trail_end_at = Time.zone.now + 30.days
  end

  def dropbox?
    dropbox_token.present?
  end

  def on_plan?(on_plan)
    return if plan.blank?

    plan.to_sym == on_plan
  end
end
