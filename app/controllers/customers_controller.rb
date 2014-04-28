class CustomersController < ApplicationController
  before_filter :set_active_nav
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
      redirect_to customers_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.messages.customer"))
    else
      Rails.logger.debug customer.to_yaml
      render "new", error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.messages.customer"))
    end
  end

  def update
    authorize! :update, customer
    if customer.update_attributes(customer_params)
      redirect_to customers_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.customer"))
    else
      render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.customer"))
    end
  end

  def destroy
    authorize! :destroy, customer
    if customer.invoices.present?
      redirect_to customers_path, alert: I18n.t(:"messages.destroy.customer.failure_dependency")
    else
      if customer.destroy
        redirect_to customers_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.messages.customer"))
      else
        redirect_to customers_path, error: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.messages.customer"))
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
      :payment_due, :email_template, :invoice_email,
      :address_attributes => [:company, :name, :address, :country, :email, :telefon, :fax, :website]
    )
  end

  def customer
    @customer ||= Customer.where(id: params.fetch(:id){nil}).first
    @customer ||= current_user.customers.new customer_params
  end
end
