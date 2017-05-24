# encoding: utf-8
# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :project
  has_many :timers, dependent: :destroy

  validates :project, :name, presence: true

  delegate :name, :label, :customer_name, to: :project, prefix: true

  def label
    "#{name} (#{I18n.t("labels.task.billable.#{billable}")})"
  end

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d
    end
    values
  end

  def start_time(date)
    started_timer = timers.where(date: date).where.not(started_at: nil).first
    return unless started_timer
    (started_timer.started_at - started_timer.sum_for_task.hours).to_i * 1000 if started_timer.started_at
  end

  def timers_sum(date)
    timers.where(date: date).inject(0) { |a, e| a + e.value }
  end
end
