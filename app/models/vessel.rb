# encoding: utf-8
# frozen_string_literal: true
class Vessel < ApplicationRecord
  belongs_to :account
  has_many :tours, dependent: :destroy
  has_many :waypoints, through: :tours

  validates :manufacturer, :vessel_type, :initial_milage, presence: true
  validates :milage, :account_id, :license_plate, presence: true

  attachment :image, content_type: ["image/jpg", "image/jpeg", "image/png"]

  before_validation :set_milage

  def set_milage
    self.milage = initial_milage if milage.zero?
  end

  def last_location
    waypoints.last.location
  end

  def name
    [
      manufacturer,
      vessel_type
    ].join(" ")
  end

  def full_name
    [
      license_plate,
      name
    ].join(", ")
  end
end
