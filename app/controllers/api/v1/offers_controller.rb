# frozen_string_literal: true

module Api
  module V1
    class OffersController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.offer", id: params[:id]))
      end

      after_action -> { pagination_header(:offers) }, only: [:index]

      TRANSITIONS = {
        "bid" => :bid!,
        "accept" => :accept!,
        "decline" => :decline!,
        "cancel" => :cancel!
      }.freeze

      def index
        authorize! :read, Offer

        scope = current_account.offers
          .filter_result(filter_params)
          .includes(:customer, :project)
          .order(ref: :desc)

        @offers = paginate(scope)
      end

      def show
        @offer = find_offer
        authorize! :read, @offer
      end

      def create
        @offer = current_account.offers.new(offer_params)
        authorize! :create, @offer

        if @offer.save
          render :show, status: :created
        else
          render json: ValidationError.new("offer.create", @offer.errors), status: :bad_request
        end
      end

      def update
        @offer = find_offer
        authorize! :update, @offer

        return render :show if @offer.update(offer_params)

        render json: ValidationError.new("offer.update", @offer.errors), status: :bad_request
      end

      def destroy
        @offer = find_offer
        authorize! :destroy, @offer

        if @offer.destroy
          render json: {message: resource_message(:offer, :destroy, :success)}
        else
          render json: ValidationError.new("offer.destroy", @offer.errors), status: :bad_request
        end
      end

      # One endpoint for the whole state machine rather than four near-identical
      # ones: the SPA sends the event name and AASM decides whether it applies.
      def transition
        @offer = find_offer
        authorize! :update, @offer

        event = TRANSITIONS[params[:event]]

        if event.blank?
          return render json: ValidationError.new("offer.transition"), status: :bad_request
        end

        @offer.public_send(event)
        render :show
      rescue AASM::InvalidTransition
        render json: ValidationError.new("offer.transition"), status: :bad_request
      end

      private def find_offer
        current_account.offers.find(params[:id])
      end

      private def filter_params
        params.permit(:state, :year)
      end

      private def offer_params
        @offer_params ||= openapi_params(::V1::Schemas::Inputs::OfferInput)
      end
    end
  end
end
