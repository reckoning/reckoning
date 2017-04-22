# encoding: utf-8
# frozen_string_literal: true
module Charts
  class ProjectBudgetService < BaseService
    attr_accessor :project, :ticks

    def initialize(project, scope)
      @project = project
      @ticks = []

      super scope
    end

    def generate_labels
      last_month = nil
      weeks do |week_start_date, _week_end_date, index|
        ticks << (index - 1) if last_month.present? && week_start_date.month != last_month
        labels << week_start_date
        last_month = week_start_date.month
      end
      ticks << (labels.size - 1)
    end

    def data
      data = super
      data[:budget] = project.budget
      data[:ticks] = ticks
      data
    end

    def generate_datasets
      return if project.budget.blank? || project.budget.zero?

      value = 0.0
      dataset = new_dataset(I18n.t(:"labels.chart.project.budget"), colors[0])
      weeks do |week_start_date, week_end_date, index|
        value += (scope.where(date: week_start_date..week_end_date).all.sum(:value) * project.rate).to_f

        dataset[:data] << value
        dataset[:zone] ||= index if week_end_date > Time.zone.now
      end
      dataset[:zone] ||= dataset[:data].count - 1

      datasets << dataset
    end

    private def start_date
      @start_date ||= begin
        start_date = project.start_date if project.start_date.present?
        start_date ||= Time.zone.parse(scope.order(:created_at).first.try(:date).to_s) if scope.order(:created_at).first.present?
        start_date ||= (Time.zone.now - 12.months)
        start_date = Time.zone.now if start_date > Time.zone.now
        start_date.to_date
      end
    end

    private def end_date
      @end_date ||= begin
        end_date = project.end_date if project.end_date.present?
        end_date ||= (Time.zone.now + 1.week)
        end_date.to_date
      end
    end

    private def weeks
      index = 0
      days = (Date.parse(start_date.to_s)..Date.parse(end_date.to_s)).to_a
      day_offset = days.first.wday - 1
      day_offset.times { days.unshift(nil) }
      days.each_slice(7) do |week_days|
        week_days.compact!
        yield(week_days.first, week_days.last, index)
        index += 1
      end
    end
  end
end
