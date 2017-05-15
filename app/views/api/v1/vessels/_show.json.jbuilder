# encoding: utf-8
# frozen_string_literal: true

json.id vessel.id
json.initial_milage vessel.initial_milage
json.milage vessel.milage
json.manufacturer vessel.manufacturer
json.vessel_type vessel.vessel_type
json.name vessel.name
json.full_name vessel.full_name
json.license_plate vessel.license_plate
json.buying_date vessel.buying_date
json.buying_price vessel.buying_price
json.created_at vessel.created_at
json.updated_at vessel.updated_at
json.last_location do
  json.partial! 'api/v1/vessels/waypoint', waypoint: vessel.last_location if vessel.last_location.present?
end
