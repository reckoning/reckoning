class TimerSerializer < BaseSerializer
  attributes :uuid, :date, :value, :position_uuid, :task_uuid,
             :task_name, :project_name, :started, :started_at, :start_time,
             :start_time_for_task, :sum_for_task

  def uuid
    object.id
  end

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
    timers.inject(0) { |a, e|  a + e.value.to_d }
  end

  def task_uuid
    object.task_id
  end

  def position_uuid
    object.position_id
  end
end
