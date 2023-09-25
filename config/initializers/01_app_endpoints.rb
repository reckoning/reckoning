# frozen_string_literal: true

require "app_endpoint_resolver"

endpoints = AppEndpointResolver.new

FRONTEND_ENDPOINT = endpoints.frontend_endpoint
API_ENDPOINT = endpoints.api_endpoint
CABLE_ENDPOINT = endpoints.cable_endpoint
