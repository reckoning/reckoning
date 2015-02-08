module Api
  module V1
    class CustomersController < Api::BaseController
      respond_to :json

      def index
        authorize! :index, Customer
        render json: current_account.customers, each_serializer: CustomerSerializer, status: :ok
      end

      def show
        authorize! :show, customer
        render json: customer, status: :ok
      end

      def create
        authorize! :create, customer
        if customer.save
          render json: customer, status: :created
        else
          render json: customer.errors, status: :bad_request
        end
      end

      private def customer_params
        @customer_params ||= params.require(:customer).permit(
          :payment_due, :email_template, :invoice_email, :default_from, :name,
          :address, :country, :email, :telefon, :fax, :website
        )
      end

      private def customer
        @customer ||= Customer.where(id: params.fetch(:id, nil)).first
        @customer ||= current_account.customers.new customer_params
      end
    end
  end
end