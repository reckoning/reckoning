class TimerSerializer < ActiveModel::Serializer
  attributes :uuid, :date, :value, :position_uuid, :task_uuid, :project_uuid,
             :task_name, :project_name, :started, :started_at, :start_time,
             :start_time_for_task, :sum_for_task, :note

  def start_time
    (object.started_at - object.value.to_d.hours).to_i * 1000 if object.started_at
  end

  def start_time_for_task
    started_timer = Timer.where(task_id: object.task_id, date: object.date, started: true).first
    return unless started_timer
    (started_timer.started_at - sum_for_task.hours).to_i * 1000 if object.started_at
  end

  def sum_for_task
    timers = Timer.where(task_id: object.task_id, date: object.date).all
    timers.inject(0) { |a, e|  a + e.value }
  end

  def task_name
    "#{object.task_name} (#{I18n.t("labels.task.billable.#{object.task.billable}")})"
  end

  def task_uuid
    object.task_id
  end

  def project_uuid
    object.task.project_id
  end

  def position_uuid
    object.position_id
  end
end
