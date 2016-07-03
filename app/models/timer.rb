require 'roo'

class Timer < ActiveRecord::Base
  belongs_to :task, touch: true
  belongs_to :user
  belongs_to :position

  before_save :convert_value
  before_save :stop_other_timers

  validates :date, :value, :task_id, presence: true

  delegate :name, :label, to: :task, prefix: true
  delegate :project, to: :task
  delegate :name, :label, :customer_name, to: :project, prefix: true

  def self.without(timer_uuids)
    where.not(id: timer_uuids)
  end

  def self.week_for(date)
    week_start = date.beginning_of_week
    week_end = date.end_of_week
    where date: [week_start..week_end]
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

  # def self.import(file, project_id)
  #   spreadsheet = open_spreadsheet(file)
  #   header = spreadsheet.row(1)
  #   project = Project.where(id: project_id).first
  #   if project.present? && valid_csv?(header)
  #     (2..spreadsheet.last_row).each do |i|
  #       row = Hash[[header, spreadsheet.row(i)].transpose]
  #       date = Date.parse(row['date'])
  #       task = Task.where(project_id: project.id, name: row['task']).first_or_create
  #       week = Week.where(user_id: project.customer.user_id, start_date: date.beginning_of_week).first_or_create
  #       week.tasks << task unless week.tasks.include?(task)
  #       where(date: row['date'], value: row['value'].gsub(',', '.'), task_id: task.id, week_id: week.id).first_or_create
  #     end
  #     return true
  #   else
  #     return false
  #   end
  # end

  # def self.valid_csv?(header)
  #   %w(date value task).reject { |h| header.include?(h) }.empty?
  # end
  #
  # def self.open_spreadsheet(file)
  #   case File.extname(file.original_filename)
  #   when ".csv" then Roo::CSV.new(file.path)
  #   else raise "Unknown file type: #{file.original_filename}"
  #   end
  # end

  def stop_other_timers
    return unless started

    self.started_at = Time.zone.now

    Timer.where(user_id: user_id, started: true).find_each do |timer|
      timer.value = timer.value + ((Time.zone.now - timer.started_at) / 1.hour)
      timer.started = false
      timer.save
    end
  end

  def start
    return if started?

    update(started: true)
  end

  def stop
    return unless started?

    timer_value = ((Time.zone.now - started_at) / 1.hour)

    update(
      started: false,
      value: ((value + timer_value) * task.project.round_up).round / task.project.round_up
    )
  end

  def convert_value
    return if value.blank? || started

    self.value = (value.hours - (value.hours % 60)) / 3600
  end

  def value_as_time
    hours = value.to_i
    minutes = format('%02d', ((value % 1) * 60).round)
    "#{hours}:#{minutes}"
  end
end
