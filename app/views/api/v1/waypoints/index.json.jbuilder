# frozen_string_literal: true

json.partial! partial: 'api/v1/waypoints/show', collection: @waypoints, as: :waypoint
