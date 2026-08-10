# frozen_string_literal: true

module Api
  module V1
    class TasksController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.base"))
      end

      def index
        authorize! :index, Task
        scope = current_account.tasks
          .includes(project: [:customer]).references(:project)
        if week_date
          @week_range = Date.parse(week_date).all_week
          scope = scope.includes(:timers).references(:timers)
            .where(timers: {user_id: current_user.id})
            .where(timers: {date: [@week_range]})
        end
        @tasks = scope.order("tasks.id ASC")
      end

      def create
        @task = Task.new task_params
        authorize! :create, @task
        if @task.save
          render status: :created
        else
          Rails.logger.info "Task Create Failed: #{@task.errors.full_messages.to_yaml}"
          render json: ValidationError.new("task.create", @task.errors), status: :bad_request
        end
      end

      def update
        @task = task_scope.find(params[:id])
        authorize! :update, @task

        return render :show if @task.update(task_update_params)

        render json: ValidationError.new("task.update", @task.errors), status: :bad_request
      end

      def destroy
        @task = task_scope.find(params[:id])
        authorize! :destroy, @task

        if @task.timers.exists?
          render json: ValidationError.new("task.destroy_failure_dependency"), status: :bad_request
        elsif @task.destroy
          render json: {message: resource_message(:task, :destroy, :success)}, status: :ok
        else
          render json: ValidationError.new("task.destroy", @task.errors), status: :bad_request
        end
      end

      private def task_scope
        current_account.tasks
      end

      private def task_update_params
        @task_update_params ||= openapi_params(::V1::Schemas::Inputs::TaskUpdateInput)
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
