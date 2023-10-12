# frozen_string_literal: true

require "roo"

class Timer < ApplicationRecord
  include Rails.application.routes.url_helpers
  include RoutingConcern
  include Swagger::Blocks

  swagger_schema :Timer do
    key :required, [:id, :date]
    property :id do
      key :type, :string
      key :format, :uuid
    end
    property :date do
      key :type, :string
      key :format, :datetime
    end
    property :value do
      key :type, :number
    end
    # json.value timer.value
    # json.note timer.note
    # json.sum_for_task timer.sum_for_task
    # json.note timer.note
    # json.started timer.started?
    # json.started_at timer.started_at
    # json.start_time timer.start_time
    # json.start_time_for_task timer.start_time_for_task
    # json.position_id timer.position_id
    # json.invoiced timer.invoiced
    # json.task_id timer.task_id
    # json.task_name timer.task_name
    # json.task_label timer.task_label
    # json.task_billable timer.task.billable
    # json.project_id timer.task.project_id
    # json.project_name timer.project_name
    # json.project_customer_name timer.project_customer_name
    # json.created_at timer.created_at
    # json.updated_at timer.updated_at
    # json.deleted timer.destroyed?
    # json.project do
    #   json.partial! "api/v1/projects/minimal", project: timer.project
    # end
    # json.task do
    #   json.partial! "api/v1/tasks/minimal", task: timer.task
    # end
    # json.links do
    #   json.self timer.url
    #   json.project timer.task.project.url
    # end
  end

  swagger_schema :TimerInput do
    key :required, [:date, :value]
    property :date do
      key :type, :string
      key :format, :datetime
    end
    property :value do
      key :type, :number
    end
  end

  belongs_to :task, touch: true
  belongs_to :user
  belongs_to :position, class_name: "InvoicePosition", optional: true

  before_save :stop_other_timers
  after_create :broadcast_create
  after_destroy :broadcast_destroy
  after_commit :broadcast_update

  validates :date, :value, presence: true

  delegate :name, :label, to: :task, prefix: true
  delegate :project, to: :task
  delegate :name, :label, :customer_name, to: :project, prefix: true

  def self.without_ids(timer_ids)
    where.not(id: timer_ids)
  end

  def self.week_for(date)
    week_start = date.beginning_of_week
    week_end = date.end_of_week
    where(date: [week_start..week_end])
  end

  def self.with_positions
    where.not(position_id: nil)
  end

  def self.uninvoiced
    where(position_id: nil)
  end

  def self.not_empty
    where.not(value: [nil, 0, "0.0", "0"])
  end

  def self.billable
    not_empty.includes(:task).where(tasks: {billable: true}).references(:task)
  end

  def self.for_project(project)
    includes(:task).where(tasks: {project_id: project}).references(:task)
  end

  def self.non_billable
    where.not(tasks: {billable: true}).references(:task)
  end

  def self.running
    where.not(started_at: nil)
  end

  def self.unnotified
    where(notified: false)
  end

  def start_time
    (started_at - value.to_d.hours).to_i * 1000 if started_at
  end

  def start_time_for_task
    task.start_time(date)
  end

  def sum_for_task
    task.timers_sum(date)
  end

  def invoiced
    position_id.present?
  end

  def started?
    started_at.present?
  end

  def stop_other_timers
    return unless started?

    Timer.where(user_id: user_id).where.not(started_at: nil).find_each do |timer|
      timer.value = timer.value + running_hours
      timer.started_at = nil
      timer.notified = false
      timer.save
    end
  end

  def start
    return if started?

    update(started_at: Time.zone.now)
  end

  def stop
    return unless started?

    new_value = value + running_hours
    new_value = round_timer(new_value) unless task.project.round_up.zero?

    update(
      started_at: nil,
      notified: false,
      value: new_value
    )
  end

  def round_timer(value)
    (((value * 60.minutes) / task.project.round_up).round * task.project.round_up) / 3600
  end

  def running_hours
    seconds = (Time.zone.now - started_at).seconds
    seconds / 1.hour
  end

  def current_value
    value + running_hours
  end

  def url
    api_v1_timer_url(self)
  end

  def to_json(*_args)
    to_jbuilder_json
  end

  def broadcast_update
    TimersChannel.broadcast_to(user, to_json)
  end

  def broadcast_create
    TimersCreateChannel.broadcast_to(user, to_json)
  end

  def broadcast_destroy
    TimersDestroyChannel.broadcast_to(user, to_json)
  end
end
