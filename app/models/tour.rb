# encoding: utf-8
# frozen_string_literal: true
class Tour < ApplicationRecord
  belongs_to :account
  belongs_to :vessel

  has_many :waypoints, dependent: :destroy, inverse_of: :tour

  validates :vessel_id, presence: true

  accepts_nested_attributes_for :waypoints

  def last_driver
    waypoints.order(time: :asc).last.driver
  end

  def to_builder
    Jbuilder.new do |vessel|
      vessel.id id
      vessel.vessel_id vessel_id
      vessel.description description
    end
  end
end
