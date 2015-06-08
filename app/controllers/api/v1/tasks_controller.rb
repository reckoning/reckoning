module Api
  module V1
    class TasksController < Api::BaseController
      around_action :authenticate_user_from_token!
      respond_to :json

      def index
        authorize! :index, Task
        scope = current_account.tasks
        if week_date
          date = Date.parse(week_date)
          scope = scope.includes(:timers).references(:timers)
                  .where(timers: { user_id: current_user.id })
                  .where(timers: { date: [date.beginning_of_week..date.end_of_week] })
        end
        render json: scope.order('tasks.id ASC'), each_serializer: TaskSerializer, status: :ok
      end

      def create
        authorize! :create, task
        if task.save
          render json: task, status: :created
        else
          render json: task.errors, status: :bad_request
        end
      end

      private def week_date
        params[:week_date]
      end

      private def project
        @project ||= current_account.projects.find(params.delete(:project_uuid))
      end

      private def task_params
        @task_params ||= params.permit(:name).merge(project_id: project.id)
      end

      private def task
        @task ||= Task.where(project_id: current_account.project_ids, id: params.fetch(:id, nil)).first
        @task ||= Task.new task_params
      end
    end
  end
end
