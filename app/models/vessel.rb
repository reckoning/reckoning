# frozen_string_literal: true

class Vessel < ApplicationRecord
  belongs_to :account
  has_many :tours, dependent: :destroy
  has_many :waypoints, through: :tours

  validates :manufacturer, :vessel_type, :initial_milage, presence: true
  validates :milage, :account_id, :license_plate, :buying_date, presence: true

  attachment :image, content_type: ['image/jpg', 'image/jpeg', 'image/png']

  before_validation :set_milage

  def set_milage
    self.milage = initial_milage if milage.zero?
  end

  def last_location
    waypoints.order(time: :asc).last
  end

  def name
    [
      manufacturer,
      vessel_type
    ].join(' ')
  end

  def full_name
    [
      license_plate,
      name
    ].join(', ')
  end

  def to_builder
    Jbuilder.new do |vessel|
      vessel.id id
      vessel.initial_milage initial_milage
      vessel.milage milage
      vessel.last_location last_location
      vessel.manufacturer manufacturer
      vessel.vessel_type vessel_type
      vessel.name name
      vessel.full_name full_name
      vessel.license_plate license_plate
      vessel.created_at created_at
      vessel.updated_at updated_at
    end
  end
end
