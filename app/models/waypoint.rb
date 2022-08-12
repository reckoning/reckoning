# frozen_string_literal: true

class Waypoint < ApplicationRecord
  belongs_to :account
  belongs_to :tour, touch: true
  belongs_to :driver,
             inverse_of: false,
             class_name: 'User'

  attr_accessor :time_date, :time_hours

  validates :time, presence: true
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
