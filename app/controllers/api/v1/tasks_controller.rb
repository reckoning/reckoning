# frozen_string_literal: true

module Api
  module V1
    class TasksController < ::Api::BaseController
      def index
        authorize! :index, Task
        scope = current_account.tasks
                               .includes(project: [:customer]).references(:project)
        if week_date
          date = Date.parse(week_date)
          scope = scope.includes(:timers).references(:timers)
                       .where(timers: { user_id: current_user.id })
                       .where(timers: { date: [date.all_week] })
        end
        @tasks = scope.order('tasks.id ASC')
      end

      def create
        @task = Task.new task_params
        authorize! :create, @task
        if @task.save
          render status: :created
        else
          Rails.logger.info "Task Create Failed: #{@task.errors.full_messages.to_yaml}"
          render json: ValidationError.new('task.create', @task.errors), status: :bad_request
        end
      end

      private def week_date
        params[:weekDate]
      end

      private def project
        @project ||= current_account.projects.find(params.delete(:project_id))
      end

      private def task_params
        @task_params ||= params.permit(:name).merge(project_id: project.id)
      end
    end
  end
end
