require 'roo'

class Timer < ActiveRecord::Base
  belongs_to :task, touch: true
  belongs_to :week
  belongs_to :position

  before_save :convert_value

  validates :week, :date, :value, :task_id, presence: true

  def self.week_for(date)
    week_start = date.beginning_of_week
    week_end = date.end_of_week
    where date: [week_start..week_end]
  end

  def self.with_positions
    where "position_id is not ?", nil
  end

  def self.import(file, project_id)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    project = Project.where(id: project_id).first
    if project.present? && valid_csv?(header)
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        date = Date.parse(row['date'])
        task = Task.where(project_id: project.id, name: row['task']).first_or_create
        week = Week.where(user_id: project.customer.user_id, start_date: date.beginning_of_week).first_or_create
        week.tasks << task unless week.tasks.include?(task)
        where(date: row['date'], value: row['value'].gsub(',', '.'), task_id: task.id, week_id: week.id).first_or_create
      end
      return true
    else
      return false
    end
  end

  def self.valid_csv?(header)
    %w(date value task).reject { |h| header.include?(h) }.empty?
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::CSV.new(file.path)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def convert_value
    return if value.blank? || !value.is_a?(String) || value.match(':').blank?
    parts = value.split(':')
    self.value = parts[0].to_d + (parts[1].to_d / 60)
  end

  def value_as_time
    hours = value.to_i
    minutes = format('%02d', ((value.to_d % 1) * 60).round)
    "#{hours}:#{minutes}"
  end
end
