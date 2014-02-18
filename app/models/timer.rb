class Timer < ActiveRecord::Base
  belongs_to :task, touch: true
  belongs_to :week
  belongs_to :position

  before_save :convert_value

  def self.week_for date
    week_start = date.beginning_of_week
    week_end = date.end_of_week
    where date: [week_start..week_end]
  end

  def convert_value
    return if value.blank? || value.match(':').blank?
    parts = value.split(':')
    self.value = parts[0].to_d + (parts[1].to_d / 60)
  end
end
