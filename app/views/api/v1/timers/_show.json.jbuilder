# frozen_string_literal: true
json.uuid timer.uuid
json.date timer.date
json.value timer.value
json.sum_for_task timer.sum_for_task
json.note timer.note
json.started timer.started
json.started_at timer.started_at
json.start_time timer.start_time
json.start_time_for_task timer.start_time_for_task
json.position_uuid timer.position_id
json.invoiced timer.invoiced
json.task_uuid timer.task_id
json.task_name timer.task_name
json.task_label timer.task_label
json.task_billable timer.task.billable
json.project_uuid timer.task.project_id
json.project_name timer.project_name
json.project_label timer.project_label
json.created_at timer.created_at
json.updated_at timer.updated_at
json.links do
  json.project do
    json.href v1_project_path(timer.task.project_id)
  end
end
