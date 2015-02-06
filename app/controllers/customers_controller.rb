class CustomersController < ApplicationController
  before_action :set_active_nav
  helper_method :customer, :sort_column

  def index
    authorize! :read, Customer
    @customers = current_account.customers
                 .order(sort_column + " " + sort_direction)
                 .page(params.fetch(:page, nil))
                 .per(20)
  end

  def show
    authorize! :read, customer
  end

  def new
    authorize! :create, Customer
    @customer = Customer.new
  end

  def edit
    authorize! :update, customer
  end

  def create
    authorize! :create, customer
    if customer.save
      redirect_to projects_path, notice: I18n.t(:"messages.customer.create.success")
    else
      flash.now[:warning] = I18n.t(:"messages.customer.create.failure")
      render "new"
    end
  end

  def update
    authorize! :update, customer
    if customer.update_attributes(customer_params)
      redirect_to "#{edit_customer_path(customer)}#{hash}", notice: I18n.t(:"messages.customer.update.success")
    else
      flash.now[:warning] = I18n.t(:"messages.customer.update.failure")
      render "edit#{hash}"
    end
  end

  def destroy
    authorize! :destroy, customer
    if customer.invoices.present?
      redirect_to projects_path, alert: I18n.t(:"messages.customer.destroy.failure_dependency")
    else
      if customer.destroy
        redirect_to projects_path, notice: I18n.t(:"messages.customer.destroy.success")
      else
        redirect_to projects_path, alert: I18n.t(:"messages.customer.destroy.failure")
      end
    end
  end

  private def sort_column
    Customer.column_names.include?(params[:sort]) ? params[:sort] : "updated_at"
  end

  private def set_active_nav
    @active_nav = 'projects'
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

  private def hash
    params.fetch(:hash, "")
  end
end
