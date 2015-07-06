module Charts
  class InvoicesService < BaseService
    attr_accessor :scope, :datasets

    def generate_datasets
      start_year = Time.zone.now - 1.year
      end_year = Time.zone.now

      return unless scope.exists?(date: start_year..end_year)

      [start_year.year, end_year.year].each do |year|
        @datasets << cumulative_dataset_for_year(year)
        @datasets << month_dataset_for_year(year)
      end
    end

    private def month_dataset_for_year(year)
      dataset = new_dataset(I18n.t(:"labels.chart.invoices.month", year: year), color_for_year[year][1])
      (1..12).map do |month|
        break if Time.zone.now.month <= month && Time.zone.now.year == year
        start_date = Time.zone.parse("#{year}-#{month}-1").beginning_of_month
        end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month

        time = (start_date.to_i * 1000)
        time = ((start_date + 1.year).to_i * 1000) if start_date.year != Time.zone.now.year
        dataset[:values] << {
          x: time,
          y: scope.where(date: start_date.to_date..end_date).all.sum(:value)
        }
      end

      dataset
    end

    private def cumulative_dataset_for_year(year)
      dataset = new_dataset(I18n.t(:"labels.chart.invoices.sum", year: year), color_for_year[year][0])
      start_of_year = Time.zone.parse("#{year}-1-1").to_date.beginning_of_month
      (1..12).each do |month|
        break if Time.zone.now.month <= month && Time.zone.now.year == year
        start_date = Time.zone.parse("#{year}-#{month}-1").beginning_of_month
        end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month

        time = (start_date.to_i * 1000)
        time = ((start_date + 1.year).to_i * 1000) if start_date.year != Time.zone.now.year
        dataset[:values] << {
          x: time,
          y: scope.where(date: start_of_year..end_date).all.sum(:value)
        }
      end

      dataset
    end

    private def color_for_year
      @color_for_year ||= {
        (Time.zone.now - 1.year).year => background_colors,
        Time.zone.now.year => colors
      }
    end
  end
end
