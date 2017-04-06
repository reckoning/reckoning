# encoding: utf-8
# frozen_string_literal: true
require 'roo'

class Timer < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :task, touch: true
  belongs_to :user
  belongs_to :position

  before_save :convert_value
  before_save :stop_other_timers

  validates :date, :value, :task_id, presence: true

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
    not_empty.includes(:task).where(tasks: { billable: true }).references(:task)
  end

  def self.for_project(project)
    includes(:task).where(tasks: { project_id: project }).references(:task)
  end

  def self.non_billable
    where.not(tasks: { billable: true }).references(:task)
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
      timer.value = timer.value + ((Time.zone.now - timer.started_at) / 1.hour)
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

    timer_value = ((Time.zone.now - started_at) / 1.hour)

    update(
      started_at: nil,
      notified: false,
      value: (((value + timer_value) * task.project.round_up) / task.project.round_up)
    )
  end

  def convert_value
    return if value.blank? || started?

    self.value = (value.hours - (value.hours % 60)) / 3600
  end

  def current_value
    timer_value = ((Time.zone.now - started_at) / 1.hour)
    value + timer_value
  end

  def to_builder
    Jbuilder.new do |timer|
      timer.id id
      timer.date date
      timer.value value
      timer.sum_for_task sum_for_task
      timer.note note
      timer.started started?
      timer.started_at started_at
      timer.start_time start_time
      timer.start_time_for_task start_time_for_task
      timer.position_id position_id
      timer.invoiced invoiced
      timer.task_id task_id
      timer.task_name task_name
      timer.task_label task_label
      timer.task_billable task.billable
      timer.project_id task.project_id
      timer.project_name project_name
      timer.project_customer_name project_customer_name
      timer.created_at created_at
      timer.updated_at updated_at
      timer.deleted destroyed?
      timer.links do
        timer.project do
          timer.href v1_project_path(task.project_id)
        end
      end
    end
  end
end
