class InvoicesChartDataService < ChartDataService
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
    [(Time.zone.now - 1.year).year, Time.zone.now.year].each_with_index do |year, index|
      @datasets << month_dataset_for_year(year, index)
      @datasets << cumulative_dataset_for_year(year, index)
    end
  end

  def month_dataset_for_year(year, index)
    dataset = new_dataset(I18n.t(:"labels.chart.invoices.month", year: year), colorsets[index])
    last_value = 0
    dataset[:data] = []
    (1..12).map do |month|
      break if Time.zone.now.month < month && Time.zone.now.year == year
      start_date = Time.zone.parse("#{year}-#{month}-1").to_date.beginning_of_month
      end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month
      value = scope.where(date: start_date..end_date).all.sum(:value)

      dataset[:data] << ((value.zero? && last_value.zero?) ? nil : value)
      last_value = value
    end

    dataset
  end

  def cumulative_dataset_for_year(year, index)
    dataset = new_dataset(I18n.t(:"labels.chart.invoices.sum", year: year), colorsets[index])
    start_of_year = Time.zone.parse("#{year}-1-1").to_date.beginning_of_month
    dataset[:data] = []
    (1..12).each do |month|
      break if Time.zone.now.month < month && Time.zone.now.year == year
      end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month
      dataset[:data] << scope.where(date: start_of_year..end_date).all.sum(:value)
    end

    dataset
  end
end
