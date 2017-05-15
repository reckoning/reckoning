# encoding: utf-8
# frozen_string_literal: true

json.id task.id
json.name task.name
json.label task.label
json.billable task.billable
json.project_id task.project_id
json.project_name task.project.name
json.project_customer_name task.project.customer_name
json.timers task.timers.where(user_id: current_user.id).order("created_at ASC") do |timer|
  json.partial! "api/v1/tasks/timers", timer: timer
end
json.created_at task.created_at
json.updated_at task.updated_at
