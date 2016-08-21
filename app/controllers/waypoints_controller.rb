# frozen_string_literal: true
class WaypointsController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def new
    @waypoint = tour.waypoints.new(
      driver_id: tour.waypoints.last.driver_id,
      milage: tour.waypoints.last.milage
    )
    authorize! :create, waypoint
  end

  def create
    authorize! :create, waypoint

    if waypoint.save
      redirect_to logbook_path, flash: { success: resource_message(:waypoint, :create, :success) }
    else
      Rails.logger.debug(waypoint.errors.to_yaml)
      flash.now[:alert] = resource_message(:waypoint, :create, :failure)
      render "new"
    end
  end

  private def waypoint
    @waypoint ||= tour.waypoints.new(waypoint_params)
  end
  helper_method :waypoint

  private def drivers
    @drivers ||= User.where(account_id: current_account.id).all
  end
  helper_method :drivers

  private def tour
    @tour ||= Tour.find_by!(id: params[:tour_id], account_id: current_account.id)
  end
  helper_method :tour

  private def waypoint_params
    @tour_params ||= params.require(:waypoint)
                     .permit(
                       :milage, :driver_id, :location, :latitude, :longitude
                     )
  end

  private def set_active_nav
    @active_nav = 'logbook'
  end
end
