class CustomersController < ApplicationController
  before_action :set_active_nav
  helper_method :customer, :sort_column

  def index
    authorize! :read, Customer
    @customers = current_user.customers.page(params.fetch(:page){nil}).per(20)
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
      redirect_to customers_path, notice: I18n.t(:"messages.customer.create.success")
    else
      flash.now[:warning] = I18n.t(:"messages.customer.create.failure")
      render "new"
    end
  end

  def update
    authorize! :update, customer
    if customer.update_attributes(customer_params)
      redirect_to customers_path, notice: I18n.t(:"messages.customer.update.success")
    else
      flash.now[:warning] = I18n.t(:"messages.customer.update.failure")
      render "edit"
    end
  end

  def destroy
    authorize! :destroy, customer
    if customer.invoices.present?
      redirect_to customers_path, alert: I18n.t(:"messages.customer.destroy.failure_dependency")
    else
      if customer.destroy
        redirect_to customers_path, notice: I18n.t(:"messages.customer.destroy.success")
      else
        redirect_to customers_path, alert: I18n.t(:"messages.customer.destroy.failure")
      end
    end
  end

  private

  def sort_column
    Customer.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end

  protected

  def set_active_nav
    @active_nav = 'customers'
  end

  def customer_params
    @customer_params ||= params.require(:customer).permit(
      :payment_due, :email_template, :invoice_email, :default_from, :company,
      :name, :address, :country, :email, :telefon, :fax, :website
    )
  end

  def customer
    @customer ||= Customer.where(id: params.fetch(:id){nil}).first
    @customer ||= current_user.customers.new customer_params
  end
end
