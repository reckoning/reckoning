# frozen_string_literal: true

json.id project.id
json.name project.name
json.label project.label
json.customer_name project.customer_name
json.customer_id project.customer_id
json.timer_values project.timer_values
json.timer_values_billable project.timer_values_billable
json.timer_values_invoiced project.timer_values_invoiced
json.timer_values_uninvoiced project.timer_values_uninvoiced
json.invoice_values project.invoice_values.to_f
json.rate project.rate.to_f
json.budget project.budget.to_f
json.budget_on_dashboard project.budget_on_dashboard
json.budget_hours project.budget_hours.to_f
json.budget_percent project.budget_percent.to_f
json.budget_percent_invoiced project.budget_percent_invoiced.to_f
json.budget_percent_uninvoiced project.budget_percent_uninvoiced.to_f
json.round_up project.round_up.to_f
json.state project.workflow_state
json.federal_state project.federal_state
json.business_days project.business_days
json.start_date project.start_date
json.end_date project.end_date
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
