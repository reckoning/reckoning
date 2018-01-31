# frozen_string_literal: true

json.id timer.id
json.date timer.date
json.value timer.value
json.sum_for_task timer.sum_for_task
json.note timer.note
json.started timer.started?
json.started_at timer.started_at
json.start_time timer.start_time
json.start_time_for_task timer.start_time_for_task
json.position_id timer.position_id
json.invoiced timer.invoiced
json.task_id timer.task_id
json.task_name timer.task_name
json.task_label timer.task_label
json.task_billable timer.task.billable
json.project_id timer.task.project_id
json.project_name timer.project_name
json.project_customer_name timer.project_customer_name
json.created_at timer.created_at
json.updated_at timer.updated_at
json.deleted timer.destroyed?
json.links do
  json.project do
    json.href v1_project_path(timer.task.project_id)
  end
end
