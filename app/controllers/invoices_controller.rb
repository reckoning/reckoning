# encoding: utf-8
# frozen_string_literal: true
class InvoicesController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav
  before_action :check_limit, only: [:new, :create]
  before_action :check_dependencies, only: [:new]

  def index
    authorize! :read, Invoice
    @invoices = current_account.invoices
                               .filter(filter_params)
                               .includes(:customer, :project).references(:customers)
                               .order(sort_column + " " + sort_direction)
                               .page(params.fetch(:page, nil))
                               .per(10)
  end

  def show
    authorize! :read, invoice
  end

  def archive
    authorize! :archive, invoice
    if current_account.dropbox?
      InvoiceDropboxWorker.perform_async invoice.id
      redirect_to invoice_path(invoice), flash: { success: I18n.t(:"messages.invoice.archive.success") }
    else
      redirect_to invoice_path(invoice), alert: I18n.t(:"messages.invoice.archive.failure")
    end
  end

  def archive_all
    authorize! :archive, invoice
    if current_account.dropbox?
      InvoiceDropboxAllWorker.perform_async current_account.id
      redirect_to invoices_path, flash: { success: I18n.t(:"messages.invoice.archive_all.success") }
    else
      redirect_to invoices_path, alert: I18n.t(:"messages.invoice.archive_all.failure")
    end
  end

  def send_mail
    authorize! :send, invoice
    if invoice.send_via_mail?
      InvoiceMailerWorker.perform_async invoice.id
      redirect_to invoice_path(invoice), flash: { success: I18n.t(:"messages.invoice.send.success") }
    else
      redirect_to invoice_path(invoice), alert: I18n.t(:"messages.invoice.send.failure")
    end
  end

  def send_test_mail
    authorize! :send, invoice

    @test_mail = TestMail.new(test_mail_params)
    if test_mail.valid?
      InvoiceTestMailerWorker.perform_async invoice.id, test_mail.email
      redirect_to invoice_path(invoice), flash: { success: I18n.t(:"messages.invoice.send_test_mail.success") }
    else
      flash.now[:alert] = I18n.t(:"messages.invoice.send_test_mail.failure")
      render "show"
    end
  end

  def pdf
    authorize! :read, invoice
    respond_to do |format|
      format.pdf do
        render invoice.pdf
      end
      unless Rails.env.production?
        format.html do
          @resource = invoice
          @preview = true
          render 'pdf', layout: 'pdf'
        end
      end
    end
  end

  def timesheet
    authorize! :read, invoice
    respond_to do |format|
      format.pdf do
        render invoice.timesheet_pdf
      end
      unless Rails.env.production?
        format.html do
          @resource = invoice
          @preview = true
          render 'timesheet_pdf', layout: 'pdf'
        end
      end
    end
  end

  def new
    authorize! :create, Invoice
    @invoice ||= if project
                   project.invoices.new
                 else
                   current_account.invoices.new
                 end
    invoice.positions << Position.new
  end

  def edit
    authorize! :update, invoice
  end

  def create
    @invoice = current_account.invoices.new(invoice_params)
    authorize! :create, invoice
    if invoice.save
      redirect_to invoices_path, flash: { success: resource_message(:invoice, :create, :success) }
    else
      flash.now[:alert] = resource_message(:invoice, :create, :failure)
      render "new"
    end
  end

  def update
    authorize! :update, invoice
    if invoice.update(invoice_params)
      redirect_to invoices_path, flash: { success: resource_message(:invoice, :update, :success) }
    else
      flash.now[:alert] = resource_message(:invoice, :update, :failure)
      render "edit"
    end
  end

  def charge
    authorize! :charge, invoice

    if invoice.charge!
      flash[:success] = I18n.t(:'messages.invoice.charge.success')
    else
      flash[:alert] = I18n.t(:'messages.invoice.charge.failure')
    end

    respond_to do |format|
      format.js { render json: {}, status: :ok }
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def pay
    authorize! :pay, invoice
    if invoice.pay!
      flash[:success] = I18n.t(:'messages.invoice.pay.success')
    else
      flash[:alert] = I18n.t(:'messages.invoice.pay.failure')
    end
    redirect_back(fallback_location: root_path)
  end

  def destroy
    authorize! :destroy, invoice

    if invoice.destroy
      flash[:success] = resource_message(:invoice, :destroy, :success)
    else
      flash[:alert] = resource_message(:invoice, :destroy, :failure)
    end

    respond_to do |format|
      format.js { render json: {}, status: :ok }
      format.html { redirect_to invoices_path }
    end
  end

  private def sort_column
    @sort_column ||= begin
      if (Invoice.column_names + %w(customers.name)).include?(params[:sort])
        params[:sort]
      else
        "ref"
      end
    end
  end
  helper_method :sort_column

  private def set_active_nav
    @active_nav = 'invoices'
  end

  private def projects
    @projects ||= current_account.projects.includes(:customer).active.order("name ASC")
  end
  helper_method :projects

  private def invoice_params
    params.require(:invoice).permit(
      :customer_id, :date, :delivery_date, :payment_due_date, :ref,
      :project_id, positions_attributes: [
        :id, :description, :hours, :rate, :value,
        :invoice_id, { timer_ids: [] }, :_destroy
      ]
    )
  end

  private def filter_params
    params.permit(:state, :year, :paid_in_year)
  end
  helper_method :filter_params

  private def project
    @project ||= current_account.projects.find_by(id: params.fetch(:project_id, nil))
  end

  private def invoice
    @invoice ||= current_account.invoices.find_by(id: params.fetch(:id, nil))
    @invoice ||= current_account.invoices.new invoice_params
  end
  helper_method :invoice

  private def check_limit
    return unless invoice_limit_reached?
    redirect_to invoices_path, alert: I18n.t(:"messages.demo_active")
  end

  private def test_mail
    @test_mail ||= TestMail.new
  end
  helper_method :test_mail

  private def test_mail_params
    params.require(:test_mail).permit(:email)
  end

  private def check_dependencies
    return if current_account.address.present?
    redirect_to "#{edit_user_registration_path}#address", alert: I18n.t(:"messages.missing_address")
  end
end
