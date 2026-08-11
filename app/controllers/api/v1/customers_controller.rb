# frozen_string_literal: true

module Api
  module V1
    class CustomersController < Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.customer", id: params[:id]))
      end

      after_action -> { pagination_header(:customers) }, only: [:index]

      def index
        authorize! :index, Customer
        @customers = paginate(current_account.customers.order(:name))
      end

      def show
        @customer = current_account.customers.find(params[:id])
        authorize! :show, @customer
      end

      def create
        @customer = current_account.customers.new(customer_params)
        authorize! :create, @customer
        if @customer.save
          render status: :created
        else
          Rails.logger.info "Customer Create Failed: #{@customer.errors.full_messages.to_yaml}"
          render json: ValidationError.new("customer.create", @customer.errors), status: :bad_request
        end
      end

      def update
        @customer = current_account.customers.find(params[:id])
        authorize! :update, @customer

        return render :show if @customer.update(customer_params)

        render json: ValidationError.new("customer.update", @customer.errors), status: :bad_request
      end

      def destroy
        @customer = current_account.customers.find(params[:id])
        authorize! :destroy, @customer
        if @customer.invoices.present?
          Rails.logger.info "Customer Destroy Failed: Invoices present"
          render json: ValidationError.new("customer.destroy_failure_dependency"), status: :bad_request
        elsif @customer.destroy
          render json: {message: resource_message(:customer, :destroy, :success)}, status: :ok
        else
          Rails.logger.info "Customer Destroy Failed: #{customer.errors.full_messages.to_yaml}"
          render json: ValidationError.new("customer.destroy", @customer.errors), status: :bad_request
        end
      end

      private def customer_params
        @customer_params ||= openapi_params(::V1::Schemas::Inputs::CustomerInput)
      end
    end
  end
end
