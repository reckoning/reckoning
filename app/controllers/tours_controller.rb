class ToursController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def new
    authorize! :create, Tour
    @tour = Tour.new
    @tour.waypoints.build
  end

  def create
    authorize! :create, tour

    if tour.save
      redirect_to logbook_path, flash: { success: resource_message(:tour, :create, :success) }
    else
      Rails.logger.debug(tour.errors.to_yaml)
      flash.now[:alert] = resource_message(:tour, :create, :failure)
      render "new"
    end
  end

  def show
    authorize! :read, tour
  end

  private def tour
    @tour ||= Tour.find_by(id: params[:id], account_id: current_account.id)
    @tour ||= Tour.new(tour_params)
  end
  helper_method :tour

  private def vessels
    @vessels ||= Vessel.where(account_id: current_account.id).all
  end
  helper_method :vessels

  private def drivers
    @drivers ||= User.where(account_id: current_account.id).all
  end
  helper_method :drivers

  private def tour_params
    @tour_params ||= params.require(:tour)
                     .permit(
                       :description, :vessel_id,
                       waypoints_attributes: [:milage, :driver_id, :location, :latitude, :longitude]
                     )
                     .merge(account_id: current_account.id)
  end

  private def set_active_nav
    @active_nav = 'logbook'
  end
end
