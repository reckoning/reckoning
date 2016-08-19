# encoding: utf-8
# frozen_string_literal: true
class Waypoint < ApplicationRecord
  belongs_to :tour, touch: true
  belongs_to :driver,
             class_name: "User"

  validates :time, :tour, :driver_id, presence: true
  validates :milage, :latitude, :longitude, :location, presence: true

  before_validation :set_time

  after_save :update_vessel

  def set_time
    self.time = Time.zone.now
  end

  def update_vessel
    tour.vessel.milage = milage
    tour.vessel.save
  end
end
