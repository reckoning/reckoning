class TimersChartDataService
  attr_accessor :labels, :scope, :datasets, :start_date, :end_date

  def initialize(scope)
    @scope = scope

    @start_date = Time.zone.today - 1.month
    @end_date = Time.zone.today

    generate_labels
    generate_datasets
  end

  def generate_labels
    @labels = []
    (start_date..end_date).each do |date|
      @labels << {
        label: date,
        title: date
      }
    end
  end

  def generate_datasets
    @datasets = []

    timers_by_project = scope.where(date: start_date..end_date).all.group_by { |timer| timer.task.project_id }
    timers_by_project.each do |_project_id, timers|
      dataset = {
        label: timers.first.task.project.name_with_customer,
        strokeColor: "rgba(151,187,205,1)",
        fillColor: "rgba(220,220,220,0.2)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        datasetStroke: false
      }
      data = []
      (start_date..end_date).each do |date|
        timers_for_date = timers.select { |timer| timer.date == date }
        value = 0.0
        timers_for_date.each do |timer|
          value += timer.value.to_f
        end
        data << value
      end
      dataset[:data] = data
      @datasets << dataset
    end
  end

  def data
    {
      labels: labels,
      datasets: @datasets
    }
  end
end

# result = []
# start_date = Time.zone.today - 1.month
# end_date = Time.zone.today
# current_account.projects.each do |project|
#   chart = { key: project.name, values: [] }

#   next if project.timers.where(date: start_date..end_date).blank?

#   (start_date..end_date).each do |date|
#     timers = current_account.timers.includes(:task).where(date: date, "tasks.project_id" => project.id).references(:task).all
#     value = 0.0
#     timers.each do |timer|
#       value += timer.value.to_d
#     end
#     chart[:values] << { x: I18n.l(date, format: :db), y: value.to_f }
#   end
#   result << chart
# end
# result
