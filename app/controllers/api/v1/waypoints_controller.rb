# encoding: utf-8
# frozen_string_literal: true
module Api
  module V1
    class WaypointsController < ::Api::BaseController
      def index
        authorize! :read, Waypoint
        scope = Waypoint.where(account_id: current_account.id)
        scope = scope.limit(limit) if limit.present?
        @waypoints = scope.all
      end

      def create
        @waypoint ||= Waypoint.new waypoint_params
        authorize! :create, @waypoint
        if @waypoint.save
          render status: :created
        else
          Rails.logger.info "Waypoint Create Failed: #{@waypoint.errors.full_messages.to_yaml}"
          render json: ValidationError.new("waypoint.create", @waypoint.errors), status: :bad_request
        end
      end

      def update
        @waypoint = Waypoint.find_by(id: params[:id], account_id: current_account.id)
        authorize! :update, @waypoint
        unless @waypoint.update(waypoint_params)
          Rails.logger.info "Waypoint Update Failed: #{@waypoint.errors.full_messages.to_yaml}"
          render json: ValidationError.new("waypoint.update", @waypoint.errors), status: :bad_request
        end
      end

      def destroy
        @waypoint = Waypoint.find_by(id: params[:id], account_id: current_account.id)
        authorize! :destroy, @waypoint
        unless @waypoint.destroy
          Rails.logger.info "Waypoint Destroy Failed: #{@waypoint.errors.full_messages.to_yaml}"
          render json: ValidationError.new("waypoint.destroy", @waypoint.errors), status: :bad_request
        end
      end

      private def limit
        @limit ||= params[:limit]
      end

      private def waypoint_params
        @waypoint_params ||= params.permit(
          :milage, :driver_id, :location, :latitude, :longitude,
          :tour_id, :time_date, :time_hours
        ).merge(account_id: current_account.id)
      end
    end
  end
end
