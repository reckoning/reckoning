module Charts
  class ProjectBudgetService < BaseService
    attr_accessor :project

    def initialize(project, scope)
      @project = project
      super scope
    end

    def generate_labels
      @labels = []
      (0..11).each do |month_offset|
        month = (Time.zone.now - month_offset.months).month
        @labels << {
          label: I18n.t('date.abbr_month_names')[month],
          title: I18n.t('date.month_names')[month]
        }
      end
      @labels = labels.reverse
    end

    def generate_datasets
      dataset = new_dataset(I18n.t(:"labels.chart.project.budget"), colorsets[1])
      dataset[:data] = []
      year = Time.zone.now.year
      budget = project.budget
      (0..11).map do |month_offset|
        month = (Time.zone.now - month_offset.months).month
        start_date = Time.zone.parse("#{year}-#{month}-1").to_date.beginning_of_month
        end_date = Time.zone.parse("#{year}-#{month}-1").to_date.end_of_month
        budget -= scope.where(date: start_date..end_date).all.sum(:value)
        dataset[:data] << budget
      end

      @datasets << dataset
    end
  end
end
