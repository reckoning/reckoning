# frozen_string_literal: true

json.id project.id
json.name project.name
json.label project.label
json.tasks project.tasks.includes(:timers).order("timers.created_at DESC") do |task|
  json.partial! "api/v1/projects/tasks", task: task
end
json.customer_name project.customer_name
json.customer_id project.customer_id
json.budget project.budget.to_f
json.budget_hours project.budget_hours.to_f
json.timer_values project.timer_values
json.state project.workflow_state
json.start_date project.start_date
json.end_date project.end_date
json.created_at project.created_at
json.updated_at project.updated_at
json.links do
  json.self project.url
end
