module Charts
  class ProjectBudgetService < BaseService
    attr_accessor :project

    def initialize(project, scope)
      @project = project

      super scope
    end

    def generate_labels
      months do |month_start_date, _month_end_date|
        labels << month_start_date
      end
    end

    def generate_datasets
      return if project.budget.blank? || project.budget.zero?

      budget = project.budget
      dataset = new_dataset(I18n.t(:"labels.chart.project.budget"), colors[0])
      months do |month_start_date, month_end_date, index|
        budget -= scope.where(date: month_start_date..month_end_date).all.sum(:value)
        if month_end_date.month == Time.zone.now.month && Time.zone.now.year == month_end_date.year
          budget -= project.timer_values_uninvoiced * project.rate
        end
        value = budget

        dataset[:data] << value
        dataset[:zone] ||= index if month_end_date > (Time.zone.now - 1.month)
      end
      dataset[:zone] ||= dataset[:data].count - 1

      @datasets << dataset
    end

    private def start_date
      @start_date ||= begin
        start_date = project.start_date if project.start_date.present?
        start_date ||= Time.zone.parse(scope.order(:created_at).first.try(:date).to_s) if scope.order(:created_at).first.present?
        start_date ||= (Time.zone.now - 12.months)
        start_date.to_date
      end
    end

    private def end_date
      @end_date ||= begin
        end_date = project.end_date if project.end_date.present?
        end_date ||= Time.zone.now
        end_date.to_date
      end
    end

    private def months(&block)
      index = 0
      (start_date.year..end_date.year).each do |year|
        month_start = (start_date.year == year) ? start_date.month : 1
        month_end = (end_date.year == year) ? end_date.month : 12

        (month_start..month_end).each_with_index do |month|
          date = Time.zone.parse("#{year}-#{month}-1")
          month_start_date = date.to_date.beginning_of_month
          month_end_date = date.to_date.end_of_month

          block.call(month_start_date, month_end_date, index)
          index += 1
        end
      end
    end
  end
end
