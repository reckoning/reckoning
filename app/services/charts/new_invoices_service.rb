module Charts
  class NewInvoicesService
    attr_accessor :scope, :dataset

    def initialize(scope)
      @scope = scope
      @dataset = {labels: [], data: []}

      generate_data
    end

    def generate_data
      # [(Time.zone.now - 1.year), Time.zone.now].each do |year|
      #   @dataset[:labels] << I18n.t(:"labels.chart.invoices.month", year: year.year)
      #   @dataset[:labels] << I18n.t(:"labels.chart.invoices.sum", year: year.year)
      #   data_month = []
      #   data_sum = []
      #   sum = 0
      #   scope.where(date: year.beginning_of_year..year.end_of_year).order(date: :asc).all.each do |invoice|
      #     data_month << { date: invoice.date, value: invoice.value }
      #     data_sum << { date: invoice.date, value: sum + invoice.value }
      #     sum = sum + invoice.value
      #   end
      #   @dataset[:data] << data_month
      #   @dataset[:data] << data_sum

      [(Time.zone.now - 1.year), Time.zone.now].each do |year|
        # @dataset[:labels] << I18n.t(:"labels.chart.invoices.month", year: year.year)
        # @dataset[:labels] << I18n.t(:"labels.chart.invoices.sum", year: year.year)
        data = []
        (1..12).each do |month|
          year = Time.zone.now
          year_prev = (Time.zone.now - 1.year)
          date = Time.zone.parse("#{year.year}-#{month}-1").to_date
          date_prev = Time.zone.parse("#{year_prev.year}-#{month}-1").to_date
          start_date = date.beginning_of_month
          end_date = date.end_of_month
          start_date_prev = date_prev.beginning_of_month
          end_date_prev = date_prev.end_of_month
          break if date > Time.zone.now
          value = scope.where(date: start_date..end_date).order(date: :asc).all.sum(:value)
          value_sum = scope.where(date: year.to_date.beginning_of_year..end_date).order(date: :asc).all.sum(:value)
          value_prev = scope.where(date: start_date_prev..end_date_prev).order(date: :asc).all.sum(:value)
          value_sum_prev = scope.where(date: year_prev.to_date.beginning_of_year..end_date_prev).order(date: :asc).all.sum(:value)
          data << { date: end_date, value_month: value, value_sum: value_sum, value_month_prev: value_prev, value_sum_prev: value_sum_prev }
        end
        @dataset[:data] << data
      end
    end
  end
end
