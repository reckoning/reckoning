# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class VesselsController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.vessel', id: params[:id]))
      end

      def index
        authorize! :index, Vessel
        @vessels = Vessel.where(account_id: current_account.id).order(updated_at: :desc)
      end

      def create
        @vessel ||= Vessel.new vessel_params
        authorize! :create, @vessel
        if @vessel.save
          send_realtime_update(@vessel)
          render status: :created
        else
          Rails.logger.info "Vessel Create Failed: #{@vessel.errors.full_messages.to_yaml}"
          render json: ValidationError.new("vessel.create", @vessel.errors), status: :bad_request
        end
      end

      def update
        @vessel = Vessel.find_by(id: params[:id], account_id: current_account.id)
        authorize! :update, @vessel
        unless @vessel.update(vessel_params)
          Rails.logger.info "Vessel Update Failed: #{@vessel.errors.full_messages.to_yaml}"
          render json: ValidationError.new("vessel.update", @vessel.errors), status: :bad_request
        end
        send_realtime_update(@vessel)
      end

      def destroy
        @vessel = Vessel.find_by(id: params[:id], account_id: current_account.id)
        authorize! :destroy, @vessel
        unless @vessel.destroy
          Rails.logger.info "Vessel Destroy Failed: #{@vessel.errors.full_messages.to_yaml}"
          render json: ValidationError.new("vessel.destroy", @vessel.errors), status: :bad_request
        end
        send_realtime_update(@vessel)
      end

      private def send_realtime_update(vessel)
        ActionCable.server.broadcast "vessels_#{current_user.id}", vessel.to_builder.target!
      end

      private def vessel_params
        @vessel_params ||= params.permit(
          :manufacturer, :vessel_type, :license_plate, :initial_milage,
          :milage, :buying_price, :buying_date, :image
        ).merge(account_id: current_account.id)
      end
    end
  end
end
