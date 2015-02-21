module Api
  class TimersController < Api::BaseController
    respond_to :json

    def index
      timers = current_user.timers
      task_id = params.fetch(:task_id, nil)
      timers.where(task_id: task_id) if task_id
      date = params.fetch(:date, nil)
      if date
        date = Date.parse(date)
        timers.where("date BETWEEN ? AND ?", date.beginning_of_week, date.end_of_week)
      end
      render json: timers
    end

    def show
      render json: timer
    end

    def create
      authorize! :create, timer
      if timer.save
        render json: timer
      else
        render json: timer.errors
      end
    end

    def update
      authorize! :create, timer
      if timer.update timer_params
        render json: timer
      else
        render json: timer.errors
      end
    end

    def destroy
      authorize! :destroy, timer
      if timer.destroy
        render json: timer
      else
        render json: timer.errors
      end
    end

    private

    def timer_params
      @timer_params ||= params.require(:timer).permit(:date, :value, :task_id)
    end

    def timer
      @timer ||= current_user.timers.where(id: params.fetch(:id, nil)).first
      @timer ||= current_user.timers.new timer_params
    end
  end
end
