# encoding: utf-8
# frozen_string_literal: true
class Customer < ActiveRecord::Base
  belongs_to :account
  has_many :projects, dependent: :destroy
  has_many :tasks, through: :projects
  has_many :timers, through: :tasks
  has_many :invoices, dependent: :destroy

  store_accessor :contact_information, :address, :country, :email, :telefon, :fax, :website

  validates :name, presence: true
  validates :email, email: true, allow_blank: true

  before_save :calculate_workdays

  def calculate_workdays
    return if employment_date.blank?
    days = 0
    date = Time.current.to_date
    while date > employment_date
      days += 1 unless date.saturday? || date.sunday?
      date -= 1.day
    end
    self.workdays = days
  end

  def overtime
    (timers.sum(:value) - (workdays / 5 * weekly_hours)).to_f
  end
end
