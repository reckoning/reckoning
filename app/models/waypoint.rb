# encoding: utf-8
# frozen_string_literal: true
class Waypoint < ApplicationRecord
  belongs_to :account
  belongs_to :tour, touch: true
  belongs_to :driver,
             class_name: "User"

  attr_accessor :time_date, :time_hours

  validates :time, :account_id, :tour_id, :driver_id, presence: true
  validates :milage, :latitude, :longitude, :location, presence: true

  before_validation :set_time

  after_save :update_vessel

  def set_time
    return if time_date.blank? || time_hours.blank?

    self.time = Time.zone.parse("#{time_date} #{time_hours}")
  end

  def update_vessel
    tour.vessel.milage = milage
    tour.vessel.save
  end
end
