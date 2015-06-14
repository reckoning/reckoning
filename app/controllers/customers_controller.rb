class CustomersController < ApplicationController
  before_action :set_active_nav
  helper_method :customer, :sort_column

  def edit
    authorize! :update, customer
  end

  def update
    authorize! :update, customer
    if customer.update_attributes(customer_params)
      redirect_to "#{edit_customer_path(customer)}#{hash}", flash: { success: I18n.t(:"messages.resource.update.success", resource: "Kunde") }
    else
      flash.now[:alert] = I18n.t(:"messages.resource.update.failure", resource: "Kunde")
      render "edit#{hash}"
    end
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
  end

  private def hash
    params.fetch(:hash, "")
  end
end
