module Api
  class TimersController < Api::BaseController
    respond_to :json

    def index
      render json: current_user.timers, root: "timers"
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
      if true#timer.update timer_params
        render json: timer
      else
        render json: timer.errors
      end
    end

    private def timer_params
      @timer_params ||= params.require(:timer).permit(:date, :value, :task_id)
    end

    private def timer
      @timer ||= current_user.timers.where(id: params.fetch(:id, nil)).first
      @timer ||= current_user.timers.new timer_params
    end
  end
end
