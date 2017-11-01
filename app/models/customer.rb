# frozen_string_literal: true

class Customer < ApplicationRecord
  belongs_to :account
  has_many :projects, dependent: :destroy
  has_many :tasks, through: :projects
  has_many :timers, through: :tasks
  has_many :invoices, dependent: :destroy

  store_accessor :contact_information, :address, :country, :email, :telefon, :fax, :website

  validates :name, presence: true
  validates :email, email: true, allow_blank: true

  def workdays
    return if employment_date.blank? || !employed?
    days = 0
    date = Time.current.to_date
    while date >= employment_date
      days += 1 unless date.saturday? || date.sunday?
      date -= 1.day
    end
    days
  end

  def employed?
    employment_date.present? && (employment_end_date.blank? || employment_end_date >= Time.zone.today)
  end

  def overtime(user_id)
    return if workdays.blank? || weekly_hours.blank?
    (timers.where(user_id: user_id).sum(:value) - scheduled_hours).to_f
  end

  def scheduled_hours
    (workdays / 5.0 * weekly_hours)
  end
end
