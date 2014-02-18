class InvoicesController < ApplicationController
  before_action :set_active_nav
  before_action :check_limit, only: [:new, :create]

  def index
    authorize! :read, Invoice
    state = params.fetch(:state){nil}
    year = params.fetch(:year){nil}
    @invoices = current_user.invoices
    if state.present? && state =~ /charged|paid|created/
      @invoices = @invoices.send(state)
    end
    if year.present? && year =~ /\d{4}/
      @invoices = @invoices.year(year)
    end
    @invoices = @invoices.includes(customer: [:address]).references(:customers)
      .order(sort_column + " " + sort_direction)
      .page(params.fetch(:page){nil})
      .per(20)
  end

  def show
    authorize! :read, invoice
    if current_user.address.blank?
      redirect_to edit_user_registration_path, alert: I18n.t(:"messages.invoice.missing_address")
    end
  end

  def pdf
    authorize! :read, invoice
    respond_to do |format|
      format.pdf {
        if File.exists?(invoice.pdf_path)
          send_file invoice.pdf_path, type: 'application/pdf', disposition: 'inline'
        else
          invoice.generate_pdf
          redirect_to invoice_path(invoice.ref)
        end
      }
      unless Rails.env.production?
        format.html {
          @resource = invoice
          render 'pdf', layout: 'pdf'
        }
      end
    end
  end

  def png
    authorize! :read, invoice
    if File.exists?(invoice.png_path)
      send_file invoice.png_path, type: 'image/png', disposition: 'inline'
    else
      render file: 'public/404.html', status: 404, layout: false
    end
  end

  def regenerate_pdf
    authorize! :read, invoice
    respond_to do |format|
      format.js {
        render json: invoice.generate_pdf
      }
      format.html {
        invoice.generate_pdf
        redirect_to invoice_path(invoice.ref)
      }
    end
  end

  def generate_positions
    authorize! :update, invoice
    raise params.inspect
  end

  def new
    authorize! :create, Invoice
    @invoice = Invoice.new
    invoice.positions << Position.new
  end

  def edit
    authorize! :update, invoice
    @ref = invoice.ref
    redirect_to invoices_path, alert: I18n.t(:"messages.invoice.not_editable") unless invoice.editable?
  end

  def create
    @invoice = current_user.invoices.new(invoice_params)
    authorize! :create, invoice
    if invoice.save
      redirect_to invoices_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.messages.invoice"))
    else
      render "new", error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.messages.invoice"))
    end
  end

  def update
    @ref = invoice.ref
    authorize! :update, invoice
    if invoice.update(invoice_params)
      redirect_to invoices_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.invoice"))
    else
      render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.invoice"))
    end
  end

  def charge
    authorize! :update, invoice
    if invoice.charge
      redirect_to :back, notice: I18n.t(:'messages.charge.invoice.success')
    else
      redirect_to :back, error: I18n.t(:'messages.charge.invoice.failure')
    end
  end

  def pay
    authorize! :update, invoice
    if invoice.pay
      redirect_to :back, notice: I18n.t(:'messages.pay.invoice.success')
    else
      redirect_to :back, error: I18n.t(:'messages.pay.invoice.failure')
    end
  end

  def check_pdf
    authorize! :update, invoice
    respond_to do |format|
      format.js {
        if invoice.present?
          render json: invoice.pdf_generating, status: :ok
        else
          render json: {}, status: :ok
        end
      }
      format.html {
        redirect_to root_path
      }
    end
  end

  def destroy
    authorize! :destroy, invoice
    if invoice.destroy
      File.delete(invoice.pdf_path) if File.exists?(invoice.pdf_path)
      redirect_to invoices_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.messages.invoice"))
    else
      redirect_to invoices_path, error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.messages.invoice"))
    end
  end

  SORT_COLUMN_MAPPING = {
    "customers.company" => "addresses.company"
  }

  private def sort_column
    @sort_column ||= begin
      column = (Invoice.column_names + %w[customers.company]).include?(params[:sort]) ? params[:sort] : "ref"
      column = SORT_COLUMN_MAPPING.fetch(column){column}
    end
  end
  helper_method :sort_column

  private def set_active_nav
    @active_nav = 'invoices'
  end

  private def projects
    @projects ||= current_user.projects
  end
  helper_method :projects

  private def invoice_params
    params.require(:invoice).permit(
      :customer_id,
      :date,
      :delivery_date,
      :payment_due_date,
      :ref,
      :project_id,
      positions_attributes: [
        :id,
        :description,
        :hours,
        :rate,
        :value,
        :invoice_id,
        {
          timer_ids: []
        },
        :_destroy
      ]
    )
  end

  private def invoice
    @invoice ||= current_user.invoices.where(ref: params.fetch(:ref){ nil }).first
  end
  helper_method :invoice

  private def check_limit
    if invoice_limit_reached?
      redirect_to invoices_path, alert: I18n.t(:"messages.demo_active")
    end
  end
end
