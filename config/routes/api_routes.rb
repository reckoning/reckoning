# encoding: utf-8
# frozen_string_literal: true

scope module: :api, constraints: { subdomain: "api" } do
  draw :api_v1_routes
end
