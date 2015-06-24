module Charts
  class ProjectBudgetService < BaseService
    attr_accessor :project

    def initialize(project, scope)
      @project = project
      super scope
    end

    def generate_labels
      @labels = []
      (0..months_count).each do |month_offset|
        month = (end_date - month_offset.months).month
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
      budget = project.budget
      (1..(months_count + 1)).to_a.reverse.map do |month_offset|
        month_start_date = (end_date - month_offset.months).to_date.beginning_of_month
        month_end_date = (end_date - month_offset.months).to_date.end_of_month
        next if month_start_date > Time.zone.now
        budget -= scope.where(date: month_start_date..month_end_date).all.sum(:value)
        dataset[:data] << budget
      end

      @datasets << dataset
    end

    private def start_date
      @start_date ||= project.start_date.try(:to_date) || scope.order(:created_at).first.try(:date) || (Time.zone.now - 12.months).to_date
    end

    private def end_date
      @end_date ||= begin
        end_date = project.end_date.try(:to_date)
        end_date = Time.zone.now.to_date if project.end_date.blank? || project.end_date < Time.zone.now.to_date
        end_date
      end
    end

    private def months_count
      (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    end
  end
end
