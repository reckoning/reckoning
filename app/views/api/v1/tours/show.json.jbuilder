# encoding: utf-8
# frozen_string_literal: true
json.partial! 'api/v1/tours/show', tour: @tour
json.waypoints @tour.waypoints.order(time: :asc) do |waypoint|
  json.partial! "api/v1/tours/waypoints", waypoint: waypoint
end
