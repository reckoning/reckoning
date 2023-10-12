# frozen_string_literal: true

require "app_endpoint_resolver"

endpoints = AppEndpointResolver.new

FRONTEND_ENDPOINT = endpoints.frontend_endpoint
FRONTEND_BASE_URL = endpoints.frontend_base_url
API_ENDPOINT = endpoints.api_endpoint
CABLE_ENDPOINT = endpoints.cable_endpoint
