# frozen_string_literal: true

json.id position.id
json.description position.description
json.hours position.hours
json.rate position.rate
json.value position.value
json.timer_ids position.timers.pluck(:id)
json.created_at position.created_at
json.updated_at position.updated_at
