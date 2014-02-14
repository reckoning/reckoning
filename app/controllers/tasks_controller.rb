class TasksController < ApplicationController

  def index
    authorize! :index, :tasks
    render json: project.tasks
  end

  def create
    authorize! :create, task
    if task.save
      render json: task
    else
      render json: task.errors
    end
  end

  private def task_params
    @task_params ||= params.require(:task).permit(:name)
  end

  private def task
    @task ||= project.tasks.new task_params
  end

  private def project
    @project ||= current_user.projects.where(id: params.fetch(:project_id, nil)).first
  end
end
