# encoding: utf-8
# frozen_string_literal: true
json.uuid task.uuid
json.name task.name
json.label task.label
json.billable task.billable
json.timers task.timers.where(user_id: current_user.id).order("created_at ASC") do |timer|
  json.partial! "api/v1/projects/timers", timer: timer
end
json.created_at task.created_at
json.updated_at task.updated_at