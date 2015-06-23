module Charts
  class ProjectTimersService < BaseService
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
      (0..11).to_a.reverse.map do |month_offset|
        start_date = (Time.zone.now - month_offset.months).to_date.beginning_of_month
        end_date = (Time.zone.now - month_offset.months).to_date.end_of_month
        value = scope.where(date: start_date..end_date).all.sum(:value)
        dataset[:data] << value
      end

      @datasets << dataset
    end
  end
end
