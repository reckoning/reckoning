module Api
  class TimersController < Api::BaseController
    respond_to :json

    def index
      render json: current_user.timers, root: false
    end

    def show
      render json: timer, root: false
    end

    def create
      authorize! :create, timer
      if timer.save
        render json: timer, root: false
      else
        render json: timer.errors, root: false
      end
    end

    def update
      authorize! :create, timer
      if timer.update timer_params
        render json: timer, root: false
      else
        render json: timer.errors, root: false
      end
    end

    def destroy
      authorize! :destroy, timer
      if timer.destroy
        render json: timer, root: false
      else
        render json: timer.errors, root: false
      end
    end

    private def timer_params
      @timer_params ||= params.require(:timer).permit(:date, :value, :task_id)
    end

    private def timer
      @timer ||= task.timers.where(id: params.fetch(:id, nil)).first
      @timer ||= task.timers.new timer_params
    end

    private def task
      @task ||= current_user.tasks.where(id: params.fetch(:task_id, nil)).first
    end
  end
end
