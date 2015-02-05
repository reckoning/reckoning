module Api
  class TasksController < Api::BaseController
    respond_to :json

    def index
      date = params.fetch(:date, nil)
      if date
        date = Date.parse(date)
        timers = current_user.timers
                 .where("date BETWEEN ? AND ?", date.beginning_of_week, date.end_of_week)
        tasks = Task.where(id: timers.map(&:task_id))
      else
        tasks = current_user.tasks
      end
      render json: tasks.order('id desc').to_json(include: :timers, methods: :project_name)
    end

    def show
      render json: task
    end

    def create
      authorize! :create, task
      if task.save
        render json: task
      else
        render json: task.errors
      end
    end

    def update
      authorize! :create, task
      if task.update task_params
        render json: task
      else
        render json: task.errors
      end
    end

    private

    def task_params
      @task_params ||= params.require(:task).permit(:name)
    end

    def task
      @task ||= current_user.tasks.where(id: params.fetch(:id, nil)).first
      @task ||= current_user.tasks.new task_params
    end
  end
end
