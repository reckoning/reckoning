# frozen_string_literal: true

module Api
  module V1
    class InvoicesController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.invoice", id: params[:id]))
      end

      after_action -> { pagination_header(:invoices) }, only: [:index]

      def index
        authorize! :read, Invoice

        scope = current_account.invoices
          .filter_result(filter_params)
          .includes(:customer, :project)
          .order(ref: :desc)

        @invoices = paginate(scope)
      end

      def show
        @invoice = find_invoice
        authorize! :read, @invoice
      end

      def create
        @invoice = current_account.invoices.new(invoice_params)
        authorize! :create, @invoice

        if @invoice.save
          render :show, status: :created
        else
          render json: ValidationError.new("invoice.create", @invoice.errors), status: :bad_request
        end
      end

      def update
        @invoice = find_invoice
        authorize! :update, @invoice

        return render :show if @invoice.update(invoice_params)

        render json: ValidationError.new("invoice.update", @invoice.errors), status: :bad_request
      end

      def destroy
        @invoice = find_invoice
        authorize! :destroy, @invoice

        if @invoice.destroy
          render json: {message: resource_message(:invoice, :destroy, :success)}
        else
          render json: ValidationError.new("invoice.destroy", @invoice.errors), status: :bad_request
        end
      end

      # created -> charged
      def charge
        @invoice = find_invoice
        authorize! :charge, @invoice

        return render :show if @invoice.charge!

        render json: ValidationError.new("invoice.charge"), status: :bad_request
      rescue Workflow::NoTransitionAllowed
        render json: ValidationError.new("invoice.charge"), status: :bad_request
      end

      # charged -> paid
      def pay
        @invoice = find_invoice
        authorize! :pay, @invoice

        return render :show if @invoice.pay!

        render json: ValidationError.new("invoice.pay"), status: :bad_request
      rescue Workflow::NoTransitionAllowed
        render json: ValidationError.new("invoice.pay"), status: :bad_request
      end

      def send_mail
        @invoice = find_invoice
        authorize! :send, @invoice

        unless @invoice.send_via_mail?
          return render json: ValidationError.new("invoice.send"), status: :bad_request
        end

        InvoiceMailerWorker.perform_async(@invoice.id)

        render json: {message: I18n.t(:"messages.invoice.send.success")}
      end

      def send_test_mail
        @invoice = find_invoice
        authorize! :send, @invoice

        test_mail = TestMail.new(email: test_mail_params[:email])

        unless test_mail.valid?
          return render json: ValidationError.new("invoice.send_test_mail", test_mail.errors), status: :bad_request
        end

        InvoiceTestMailerWorker.perform_async(@invoice.id, test_mail.email)

        render json: {message: I18n.t(:"messages.invoice.send_test_mail.success")}
      end

      private def find_invoice
        current_account.invoices.find(params[:id])
      end

      private def filter_params
        params.permit(:state, :year, :quarter, :month, :paid_in_year, :paid_in_quarter, :paid_in_month)
      end

      private def invoice_params
        @invoice_params ||= openapi_params(::V1::Schemas::Inputs::InvoiceInput)
      end

      private def test_mail_params
        @test_mail_params ||= openapi_params(::V1::Schemas::Inputs::TestMailInput)
      end
    end
  end
end
