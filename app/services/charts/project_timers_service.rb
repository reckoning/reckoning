module Charts
  class ProjectTimersService < BaseService
    attr_accessor :project

    def initialize(project, scope)
      @project = project

      super scope
    end

    def generate_datasets
      project.tasks.each_with_index do |task, index|
        dataset = new_dataset(task.name, colors[index])
        (0..months_count).to_a.reverse.map do |month_offset|
          month_start_date = (end_date - month_offset.months).beginning_of_month
          month_end_date = (end_date - month_offset.months).to_date.end_of_month
          value = scope.where(task: task, date: month_start_date.to_date..month_end_date).all.sum(:value)
          dataset[:values] << {
            x: (month_start_date.to_i * 1000),
            y: value
          }
        end
        @datasets << dataset if dataset[:values].present?
      end
    end

    private def start_date
      @start_date ||= begin
        start_date = project.start_date if project.start_date.present?
        start_date ||= Time.zone.parse(scope.order(:created_at).first.try(:date)) if scope.order(:created_at).first.present?
        start_date ||= (Time.zone.now - 12.months)
        start_date
      end
    end

    private def end_date
      @end_date ||= begin
        end_date = project.end_date if project.end_date.present?
        end_date ||= Time.zone.now
        end_date
      end
    end

    private def months_count
      (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    end
  end
end
