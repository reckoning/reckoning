# frozen_string_literal: true

class AccountsController < ApplicationController
  include ResourceHelper

  before_action :check_registration_setting, only: %i[new create]
  before_action :set_active_nav, except: %i[new create]
  before_action :authenticate_user!, except: %i[new create]
  skip_authorization_check only: %i[new create]

  def new
    @active_nav = "registration"
    redirect_to new_user_session_path if current_account.present?
    @account = Account.new plan: params[:plan]
    @account.users.build
    render layout: "landing_page"
  end

  def edit
    authorize! :update, account
  end

  def create
    @active_nav = "registration"
    if account.save
      redirect_to new_user_session_path, flash: {success: resource_message(:account, :create, :success)}
    else
      render "new", alert: resource_message(:account, :create, :failure), layout: "landing_page"
    end
  end

  def update
    authorize! :update, account
    if account.update(account_params)
      redirect_to "#{edit_account_path}#{hash}", flash: {success: resource_message(:account, :update, :success)}
    else
      flash.now[:alert] = resource_message(:account, :update, :failure)
      render "edit"
    end
  end

  private def set_active_nav
    @active_nav = "account"
  end

  private def account_params
    @account_params ||= params.require(:account).permit(
      :plan, :tax, :vat_id, :provision, :bank, :account_number, :bank_code, :bic, :iban,
      :signature, :name, :address, :country, :public_email, :subdomain, :telefon, :fax, :website,
      :stripe_email, :stripe_token, :office_space, :deductible_office_space, :offer_headline,
      users_attributes: %i[email password password_confirmation]
    )
  end

  private def account
    @account ||= current_account
    @account ||= Account.new account_params
  end
  helper_method :account

  private def hash
    params.fetch(:hash, "")
  end

  private def check_registration_setting
    return if registration_enabled? || params[:stripe_test].present?

    redirect_to root_path
  end
end
