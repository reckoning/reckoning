class VesselsController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def new
    authorize! :create, Vessel
    @vessel = Vessel.new
  end

  def create
    authorize! :create, vessel

    if vessel.save
      redirect_to logbook_path, flash: { success: resource_message(:vessel, :create, :success) }
    else
      flash.now[:alert] = resource_message(:vessel, :create, :failure)
      render "new"
    end
  end

  def show
    authorize! :read, vessel
  end

  private def vessel
    @vessel ||= Vessel.new(vessel_params)
  end
  helper_method :vessel

  private def manufacturers
    @manufacturers ||= Vessel.where(account_id: current_account.id).map(&:manufacturer)
    @manufacturers += [vessel.manufacturer] if vessel.manufacturer.present?
    @manufacturers.uniq
  end
  helper_method :manufacturers

  private def vessel_params
    @vessel_params ||= params.require(:vessel)
                       .permit(
                         :manufacturer, :vessel_type, :license_plate, :initial_milage,
                         :buying_price, :image
                       )
                       .merge(account_id: current_account.id)
  end

  private def set_active_nav
    @active_nav = 'logbook'
  end
end
