# encoding: utf-8
# frozen_string_literal: true
json.id tour.id
json.description tour.description
json.vessel_id tour.vessel.id
json.vessel_license_plate tour.vessel.license_plate
json.vessel_name tour.vessel.name
json.vessel_full_name tour.vessel.full_name
json.vessel_milage tour.vessel.milage
json.last_driver_id tour.last_driver.id if tour.last_driver.present?
json.created_at tour.created_at
json.updated_at tour.updated_at
