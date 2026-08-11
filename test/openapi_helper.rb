# frozen_string_literal: true

require_relative "test_helper"
require "openapi_ruby/minitest"

# One `api_path` per test class, one class per file. `assert_api_response`
# resolves a call to the first declared api_path whose template has a path
# param, so sibling paths like /timers/{id} and /timers/{id}/start silently
# answer for each other when they share a class.
