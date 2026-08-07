# frozen_string_literal: true

json.id task.id
json.name task.name
json.label task.label
json.billable task.billable
json.project_id task.project_id
json.project_name task.project.name
json.project_customer_name task.project.customer_name
task_timers = task.timers.where(user_id: current_user.id)
task_timers = task_timers.where(date: @week_range) if @week_range
json.timers task_timers.order("created_at ASC") do |timer|
  json.partial! "api/v1/tasks/timers", timer: timer
end
json.created_at task.created_at
json.updated_at task.updated_at
