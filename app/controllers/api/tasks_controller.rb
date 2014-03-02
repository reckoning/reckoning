module Api
  class TasksController < Api::BaseController
    respond_to :json

    def index
      render json: current_user.tasks.order('id desc'), root: false
    end

    def show
      render json: task, root: false
    end

    def create
      authorize! :create, task
      if task.save
        render json: task, root: false
      else
        render json: task.errors, root: false
      end
    end

    def update
      authorize! :create, task
      if task.update task_params
        render json: task, root: false
      else
        render json: task.errors, root: false
      end
    end

    private def task_params
      @task_params ||= params.require(:task).permit(:name)
    end

    private def task
      @task ||= current_user.tasks.where(id: params.fetch(:id, nil)).first
      @task ||= current_user.tasks.new task_params
    end
  end
end
