module Charts
  class InvoicesService < BaseService
    attr_accessor :scope

    def generate_labels
      date = Time.zone.now
      (1..12).map do |month|
        @labels << "#{date.year}-#{month}-1"
      end
    end

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
        start_date = Time.zone.parse("#{year}-#{month}-1").beginning_of_month
        end_date = Time.zone.parse("#{year}-#{month}-1").end_of_month
        break if end_date > Time.zone.now

        dataset[:data] << scope.where(date: start_date.to_date..end_date).all.sum(:value)
      end

      dataset
    end

    private def cumulative_dataset_for_year(year)
      dataset = new_dataset(I18n.t(:"labels.chart.invoices.sum", year: year), color_for_year[year][0])
      start_of_year = Time.zone.parse("#{year}-1-1").to_date.beginning_of_month
      (1..12).each do |month|
        end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month

        dataset[:data] << scope.where(date: start_of_year..end_date).all.sum(:value)
        dataset[:zone] ||= month - 1 if month >= (Time.zone.now - 1.month).month && Time.zone.now.year == end_date.year
      end
      dataset[:zone] ||= dataset[:data].count - 1

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
