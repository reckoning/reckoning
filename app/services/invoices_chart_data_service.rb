class InvoicesChartDataService
  attr_accessor :labels, :scope, :datasets

  def initialize(scope)
    @scope = scope

    generate_labels
    generate_datasets
  end

  def generate_labels
    @labels = []
    (1..12).each do |month|
      @labels << {
        label: I18n.t('date.abbr_month_names')[month],
        title: I18n.t('date.month_names')[month]
      }
    end
  end

  def generate_datasets
    @datasets = []

    [Time.zone.now.year, (Time.zone.now - 1.year).year].each do |year|
      dataset_cumulative = {
        label: I18n.t(:"labels.chart.invoices.sum", year: year),
        strokeColor: "rgba(151,187,205,1)",
        fillColor: "rgba(220,220,220,0.2)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        datasetStroke: false
      }
      dataset_month = {
        label: I18n.t(:"labels.chart.invoices.month", year: year),
        strokeColor: "rgba(151,187,205,1)",
        fillColor: "rgba(220,220,220,0.2)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        datasetStroke: false
      }
      data_month = []
      data_cumulative = []
      start_of_year = Time.zone.parse("#{year}-1-1").to_date.beginning_of_month
      (1..12).each do |month|
        start_date = Time.zone.parse("#{year}-#{month}-1").to_date.beginning_of_month
        end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month
        data_month << scope.where(date: start_date..end_date).all.sum(:value)
        data_cumulative << scope.where(date: start_of_year..end_date).all.sum(:value)
      end
      dataset_month[:data] = data_month
      dataset_cumulative[:data] = data_cumulative
      @datasets << dataset_month
      @datasets << dataset_cumulative
    end
  end

  def data
    {
      labels: labels,
      datasets: @datasets
    }
  end
end
