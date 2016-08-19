# encoding: utf-8
# frozen_string_literal: true
class Tour < ApplicationRecord
  belongs_to :account
  belongs_to :vessel

  has_many :waypoints, dependent: :destroy, inverse_of: :tour

  validates :vessel_id, presence: true

  accepts_nested_attributes_for :waypoints
end
