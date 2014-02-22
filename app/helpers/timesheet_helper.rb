module TimesheetHelper
  def week_days_for date
    @week_days ||= begin
      first = date.beginning_of_week
      last = date.end_of_week
      week = (first..last).to_a
    end
  end

  def decimal_to_time value
    hours = value.to_i
    minutes = format('%02d', ((value.to_d % 1) * 60).round)
    "#{hours}:#{minutes}"
  end
end
