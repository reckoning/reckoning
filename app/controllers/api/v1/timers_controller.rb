module Api
  module V1
    class TimersController < Api::BaseController
      before_action :authenticate_user_from_token!
      respond_to :json

      def index
        scope = current_user.timers
        scope = scope.where(date: date) if date
        render json: scope.order('created_at ASC'), each_serializer: TimerSerializer, status: :ok
      end

      def create
        authorize! :create, timer
        if timer.save
          render json: timer, status: :created
        else
          render json: timer.errors, status: :bad_request
        end
      end

      def update
        authorize! :update, timer
        if timer.update(timer_params)
          render json: timer, status: :ok
        else
          render json: timer.errors, status: :bad_request
        end
      end

      def stop
        authorize! :stop, timer
        if timer.update(started: false, value: timer.value.to_d + ((Time.now - timer.started_at) / 1.hour))
          render json: timer, status: :ok
        else
          render json: timer.errors, status: :bad_request
        end
      end

      def start
        authorize! :start, timer
        if timer.update(started: true)
          render json: timer, status: :ok
        else
          render json: timer.errors, status: :bad_request
        end
      end

      def destroy
        authorize! :destroy, timer
        if timer.position.blank?
          if timer.destroy
            render json: timer, status: :ok
          else
            render json: timer.errors, status: :bad_request
          end
        else
          render json: { message: I18n.t(:"messages.timer.destroy.failure") }, status: :bad_request
        end
      end

      private def date
        params[:date]
      end

      private def task
        @task ||= current_account.tasks.find(params.delete(:task_uuid))
      end

      private def timer_params
        @timer_params ||= params.require(:timer).permit(:date, :value, :started, :note).merge(
          task_id: task.id,
          user_id: current_user.id
        )
      end

      private def timer
        @timer ||= Timer.where(user_id: current_user.id, id: params.fetch(:id, nil)).first
        @timer ||= Timer.new timer_params
      end
    end
  end
end
