# encoding: utf-8
# frozen_string_literal: true
class CustomersController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav
  helper_method :customer, :sort_column

  def edit
    authorize! :update, customer
  end

  def update
    authorize! :update, customer
    if customer.update_attributes(customer_params)
      redirect_to "#{edit_customer_path(customer)}#{hash}", flash: { success: resource_message(:customer, :update, :success) }
    else
      flash.now[:alert] = resource_message(:customer, :update, :failure)
      render "edit#{hash}"
    end
  end

  private def set_active_nav
    @active_nav = 'projects'
  end

  private def customer_params
    @customer_params ||= params.require(:customer).permit(
      :payment_due, :email_template, :invoice_email, :default_from, :name,
      :address, :country, :email, :telefon, :fax, :website, :employment_date, :weekly_hours
    )
  end

  private def customer
    @customer ||= Customer.where(id: params.fetch(:id, nil)).first
  end

  private def hash
    params.fetch(:hash, "")
  end
end
