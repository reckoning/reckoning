class InvoicesController < ApplicationController
  before_action :set_active_nav
  before_action :check_limit, only: [:new, :create]
  before_action :check_dependencies, only: [:new]

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
    @invoices = @invoices.includes(:customer).references(:customers)
      .order(sort_column + " " + sort_direction)
      .page(params.fetch(:page){nil})
      .per(20)
  end

  def show
    authorize! :read, invoice
    if invoice.pdf_not_present_and_not_generating? || !invoice.pdf_present_and_up_to_date?
      invoice.generate_pdf
    end
  end

  def archive
    authorize! :archive, invoice
    if current_user.has_dropbox?
      if invoice.files_present?
        InvoiceDropboxWorker.perform_async invoice.id
        redirect_to invoice_path(invoice), notice: I18n.t(:"messages.invoice.archive.success")
      else
        redirect_to invoice_path(invoice), warning: I18n.t(:"messages.invoice.files_missing")
      end
    else
      redirect_to invoice_path(invoice), warning: I18n.t(:"messages.invoice.archive.failure")
    end
  end

  def archive_all
    authorize! :archive, invoice
    if current_user.has_dropbox?
      InvoiceDropboxAllWorker.perform_async current_user.id
      redirect_to invoices_path, notice: I18n.t(:"messages.invoice.archive_all.success")
    else
      redirect_to invoices_path, warning: I18n.t(:"messages.invoice.archive_all.failure")
    end
  end

  def send_mail
    authorize! :send, invoice
    if invoice.send_via_mail?
      if invoice.files_present?
        InvoiceMailerWorker.perform_async invoice.id
        redirect_to invoice_path(invoice), notice: I18n.t(:"messages.invoice.send.success")
      else
        redirect_to invoice_path(invoice), warning: I18n.t(:"messages.invoice.files_missing")
      end
    else
      redirect_to invoice_path(invoice), warning: I18n.t(:"messages.invoice.send.failure")
    end
  end

  def send_test_mail
    authorize! :send, invoice

    @test_mail = TestMail.new(test_mail_params)
    if test_mail.valid?
      InvoiceTestMailerWorker.perform_async invoice.id, test_mail.email
      redirect_to invoice_path(invoice), notice: I18n.t(:"messages.invoice.send_test_mail.success")
    else
      flash.now[:warning] = I18n.t(:"messages.invoice.send_test_mail.failure")
      render "show"
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
          redirect_to invoice_path(invoice)
        end
      }
      unless Rails.env.production?
        format.html {
          @resource = invoice
          @preview = true
          render 'pdf', layout: 'pdf'
        }
      end
    end
  end

  def timesheet
    authorize! :read, invoice
    respond_to do |format|
      format.pdf {
        if File.exists?(invoice.timesheet_path)
          send_file invoice.timesheet_path, type: 'application/pdf', disposition: 'inline'
        else
          invoice.generate_pdf
          redirect_to invoice_path(invoice)
        end
      }
      unless Rails.env.production?
        format.html {
          @resource = invoice
          @preview = true
          render 'timesheet_pdf', layout: 'pdf'
        }
      end
    end
  end

  def regenerate_pdf
    authorize! :read, invoice
    respond_to do |format|
      format.js {
        render json: invoice.generate_pdf.to_json
      }
      format.html {
        invoice.generate_pdf
        redirect_to invoice_path(invoice)
      }
    end
  end

  def new
    authorize! :create, Invoice
    invoice.positions << Position.new
  end

  def edit
    authorize! :update, invoice
  end

  def create
    @invoice = current_user.invoices.new(invoice_params)
    authorize! :create, invoice
    if invoice.save
      redirect_to invoices_path, notice: I18n.t(:"messages.invoice.create.success")
    else
      flash.now[:warning] = I18n.t(:"messages.invoice.create.failure")
      render "new"
    end
  end

  def update
    authorize! :update, invoice
    if invoice.update(invoice_params)
      redirect_to invoices_path, notice: I18n.t(:"messages.invoice.update.success")
    else
      flash.now[:warning] = I18n.t(:"messages.invoice.update.failure")
      render "edit"
    end
  end

  def charge
    authorize! :charge, invoice
    invoice.charge
    invoice.save
    respond_to do |format|
      if invoice.reload.charged?
        flash[:notice] = I18n.t(:'messages.invoice.charge.success')
        format.js {
          render json: {}, status: :ok
        }
        format.html {
          redirect_to :back
        }
      else
        flash[:alert] = I18n.t(:'messages.invoice.charge.failure')
        format.js {
          render json: {}, status: :ok
        }
        format.html {
          redirect_to :back
        }
      end
    end
  end

  def pay
    authorize! :pay, invoice
    invoice.pay
    invoice.save
    if invoice.reload.paid?
      redirect_to :back, notice: I18n.t(:'messages.invoice.pay.success')
    else
      redirect_to :back, alert: I18n.t(:'messages.invoice.pay.failure')
    end
  end

  def check_pdf
    authorize! :check, invoice
    respond_to do |format|
      format.js {
        if invoice.present?
          if invoice.pdf_generating?
            data = false
          else
            data = {}
            data[:invoice] = invoice_pdf_path(invoice, invoice.invoice_file)
            if invoice.timers.present?
              data[:timesheet] = timesheet_pdf_path(invoice, invoice.timesheet_file)
            end
          end
          render json: data, status: :ok
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
      File.delete(invoice.timesheet_path) if File.exists?(invoice.timesheet_path)

      flash[:notice] = I18n.t(:"messages.invoice.destroy.success")
      respond_to do |format|
        format.js {
          render json: {}, status: :ok
        }
        format.html {
          redirect_to invoices_path
        }
      end
    else
      flash[:alert] = I18n.t(:"messages.invoice.destroy.failure")
      respond_to do |format|
        format.js {
          render json: {}, status: :ok
        }
        format.html {
          redirect_to invoices_path
        }
      end
    end
  end

  private

  def sort_column
    @sort_column ||= begin
      column = (Invoice.column_names + %w[customers.company]).include?(params[:sort]) ? params[:sort] : "ref"
    end
  end
  helper_method :sort_column

  def set_active_nav
    @active_nav = 'invoices'
  end

  def projects
    @projects ||= current_user.projects
  end
  helper_method :projects

  def invoice_params
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

  def invoice
    @invoice ||= current_user.invoices.where(id: params.fetch(:id, nil)).first
    @invoice ||= current_user.invoices.new
  end
  helper_method :invoice

  def check_limit
    if invoice_limit_reached?
      redirect_to invoices_path, alert: I18n.t(:"messages.demo_active")
    end
  end

  def test_mail
    @test_mail ||= TestMail.new
  end
  helper_method :test_mail

  def test_mail_params
    params.require(:test_mail).permit(:email)
  end

  def check_dependencies
    if current_user.address.blank?
      redirect_to "#{edit_user_registration_path}#address", alert: I18n.t(:"messages.invoice.missing_address")
      return
    end
  end
end
