class TasksController < ApplicationController

  def index
    authorize! :index, Task
    respond_to do |format|
      format.js {
        render json: project.tasks, root: false
      }
      format.html {
        redirect_to root_path
      }
    end
  end

  def index_for_date
    authorize! :index, Task
    respond_to do |format|
      format.js {
        project = current_user.projects.where(id: project_id).first
        tasks = project.tasks.includes(:timers)
          .where("timers.date BETWEEN ? AND ?", date.beginning_of_month, date.end_of_month).references(:timers)
          .where("timers.position_id is ?", nil).references(:timers)
          .to_a
        render json: {body: render_to_string(partial: "list", locals: {tasks: tasks})}
      }
      format.html {
        redirect_to root_path
      }
    end
  end

  def create
    authorize! :create, task
    respond_to do |format|
      format.js {

        if task.save
          render json: task
        else
          render json: task.errors
        end
      }
      format.html {
        redirect_to root_path
      }
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

  private def date
    @date ||= (params[:date].present? ? Date.parse(params.fetch(:date, nil)) : Date.today)
  end

  private def project_id
    @project_id ||= params.fetch(:project_id, nil)
  end
end
