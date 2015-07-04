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
          month_start_date = (end_date - month_offset.months).to_date.beginning_of_month
          month_end_date = (end_date - month_offset.months).to_date.end_of_month
          next if month_start_date > Time.zone.now
          value = scope.where(task: task, date: month_start_date..month_end_date).all.sum(:value)
          dataset[:values] << {
            label: (month_start_date.to_time.to_i * 1000),
            y: value
          }
        end
        @datasets << dataset if dataset[:values].present?
      end
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
