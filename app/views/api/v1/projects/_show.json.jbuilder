# frozen_string_literal: true

json.id project.id
json.name project.name
json.customer_name project.customer_name
json.label project.label
json.customer_id project.customer_id
json.workflow_state project.workflow_state
json.rate project.rate
json.budget project.budget
json.budget_hours project.budget_hours
json.budget_on_dashboard project.budget_on_dashboard
json.round_up project.round_up
json.invoice_addition project.invoice_addition
json.start_date project.start_date
json.end_date project.end_date
json.timer_values project.timer_values
# Dividing by a budget of zero is what the ERB guarded against before it drew
# the bar, so the client gets nothing to draw rather than an infinity.
json.budget_percent((project.budget_hours.to_d.zero? && project.budget.to_d.zero?) ? nil : project.budget_percent)
json.tasks project.tasks.includes(:timers).order("timers.created_at DESC") do |task|
  json.partial! "api/v1/projects/tasks", task: task
end
json.created_at project.created_at
json.updated_at project.updated_at
json.links do
  json.show do
    json.href v1_project_path(project.id)
  end
end
