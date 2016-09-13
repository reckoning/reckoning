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

  def workdays
    return if employment_date.blank?
    days = 0
    date = Time.current.to_date - 1.day
    while date > employment_date
      days += 1 unless date.saturday? || date.sunday?
      date -= 1.day
    end
    days
  end

  def overtime(user_id)
    return if workdays.blank? || weekly_hours.blank?
    (timers.where(user_id: user_id).sum(:value) - (workdays / 5.0 * weekly_hours)).to_f
  end
end
