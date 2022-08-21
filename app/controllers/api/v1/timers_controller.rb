# frozen_string_literal: true

module Api
  module V1
    class TimersController < Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.timer', id: params[:id]))
      end

      def index
        authorize! :index, Timer
        scope = current_account.timers
        scope = scope.where(date: date) if date
        scope = scope.where(date: date_range) if date_range
        scope = scope.for_project(project_id) if project_id
        scope = scope.uninvoiced if params[:uninvoiced].present?
        scope = scope.billable if params[:billable].present?
        scope = scope.running if params[:running].present?
        scope = scope.limit(limit) if limit
        @timers = scope.order(updated_at: :desc)
      end

      def create
        @timer ||= current_user.timers.new timer_params
        authorize! :create, @timer
        if @timer.save
          @timer.start if start_timer?
          send_realtime_update(@timer)
          render status: :created
        else
          Rails.logger.info "Timer Create Failed: #{@timer.errors.full_messages.to_yaml}"
          render json: ValidationError.new('timer.create', @timer.errors), status: :bad_request
        end
      end

      def update
        @timer = current_user.timers.find(params[:id])
        authorize! :update, @timer
        unless @timer.update(timer_params)
          Rails.logger.info "Timer Update Failed: #{@timer.errors.full_messages.to_yaml}"
          render json: ValidationError.new('timer.update', @timer.errors), status: :bad_request
        end
        @timer.start if start_timer?
        send_realtime_update(@timer)
      end

      def stop
        @timer = current_user.timers.find(params[:id])
        authorize! :stop, @timer
        unless @timer.stop
          Rails.logger.info "Timer Stop Failed: #{@timer.to_yaml}"
          render json: { message: I18n.t(:'messages.timer.stop.failure') }, status: :bad_request
        end
        send_realtime_update(@timer)
      end

      def start
        @timer = current_user.timers.find(params[:id])
        authorize! :start, @timer
        unless @timer.start
          Rails.logger.info "Timer Start Failed: #{@timer.to_yaml}"
          render json: { message: I18n.t(:'messages.timer.start.failure') }, status: :bad_request
        end
        send_realtime_update(@timer)
      end

      def destroy
        @timer = current_user.timers.find(params[:id])
        authorize! :destroy, @timer
        if @timer.position.blank?
          unless @timer.destroy
            Rails.logger.info "Timer Destroy Failed: #{@timer.errors.full_messages.to_yaml}"
            render json: ValidationError.new('timer.destroy', @timer.errors), status: :bad_request
          end
          send_realtime_update(@timer)
        else
          Rails.logger.info 'Timer Destroy Failed: Timer allready on Invoice'
          render json: { message: I18n.t(:'messages.timer.destroy.failure') }, status: :bad_request
        end
      end

      private def date
        @date ||= params[:date]
      end

      private def date_range
        return if start_date.blank? || end_date.blank?

        @date_range ||= (start_date..end_date)
      end

      private def start_date
        @start_date ||= params[:startDate]
      end

      private def end_date
        @end_date ||= params[:endDate]
      end

      private def project_id
        @project_id ||= params[:projectId]
      end

      private def limit
        @limit ||= params[:limit]
      end

      private def task
        @task ||= current_account.tasks.find(params.delete(:task_id))
      end

      private def start_timer?
        params.delete(:started)
      end

      private def send_realtime_update(timer)
        ActionCable.server.broadcast "timers_#{current_user.id}_#{timer.date}", timer.to_builder.target!
        ActionCable.server.broadcast "timers_#{current_user.id}_all", timer.to_builder.target!
      end

      private def timer_params
        @timer_params ||= params.permit(:date, :value, :note).merge(
          task_id: task.id,
          user_id: current_user.id
        )
      end
    end
  end
end
