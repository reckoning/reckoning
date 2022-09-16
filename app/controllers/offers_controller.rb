# frozen_string_literal: true

class OffersController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav
  before_action :check_dependencies, only: [:new]

  def index
    authorize! :read, Invoice
    @offers = current_account.offers
      .filter_result(filter_params)
      .includes(:customer, :project).references(:customers)
      .order("#{sort_column} #{sort_direction}")
      .page(params.fetch(:page, nil))
      .per(10)
  end

  def show
    authorize! :read, offer
  end

  def pdf
    authorize! :read, offer
    respond_to do |format|
      format.pdf do
        render offer.pdf
      end
      unless Rails.env.production?
        format.html do
          render 'pdf', layout: 'pdf', locals: { resource: offer }
        end
      end
    end
  end

  def new
    authorize! :create, Offer
    @offer ||= if project
                 project.offers.new
               else
                 current_account.offers.new
               end
    offer.positions << OfferPosition.new
  end

  def edit
    authorize! :update, offer
  end

  def create
    @offer = current_account.offers.new(offer_params)
    authorize! :create, offer
    if offer.save
      redirect_to offers_path, flash: { success: resource_message(:offer, :create, :success) }
    else
      flash.now[:alert] = resource_message(:offer, :create, :failure)
      render 'new'
    end
  end

  def update
    authorize! :update, offer
    if offer.update(offer_params)
      redirect_to offers_path, flash: { success: resource_message(:offer, :update, :success) }
    else
      flash.now[:alert] = resource_message(:offer, :update, :failure)
      render 'edit'
    end
  end

  def destroy
    authorize! :destroy, offer

    if offer.destroy
      flash[:success] = resource_message(:offer, :destroy, :success)
    else
      flash[:alert] = resource_message(:offer, :destroy, :failure)
    end

    respond_to do |format|
      format.js { render json: {}, status: :ok }
      format.html { redirect_to offers_path }
    end
  end

  private def sort_column
    @sort_column ||= if (Offer.column_names + %w[customers.name]).include?(params[:sort])
                       params[:sort]
                     else
                       'ref'
                     end
  end
  helper_method :sort_column

  private def set_active_nav
    @active_nav = 'offers'
  end

  private def projects
    @projects ||= current_account.projects.includes(:customer).active.order('name ASC')
  end
  helper_method :projects

  private def offer_params
    params.require(:offer).permit(
      :customer_id, :date, :ref, :description,
      :project_id, positions_attributes: %i[
        id description hours rate value
        position_id _destroy
      ]
    )
  end

  private def filter_params
    params.permit(:state, :year)
  end
  helper_method :filter_params

  private def project
    @project ||= current_account.projects.find_by(id: params.fetch(:project_id, nil))
  end

  private def offer
    @offer ||= current_account.offers.find_by(id: params.fetch(:id, nil))
    @offer ||= current_account.offers.new offer_params
  end
  helper_method :offer

  private def check_dependencies
    return if current_account.address.present?

    redirect_to "#{edit_user_registration_path}#address", alert: I18n.t(:'messages.missing_address')
  end
end
