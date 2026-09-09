# frozen_string_literal: true

class AccountsController < ApplicationController
  include ResourceHelper

  # Signing up is all that is left here: the account's own settings are the
  # SPA's, and saving them goes through /api/v1.
  before_action :check_registration_setting, only: %i[new create]
  skip_authorization_check only: %i[new create]

  def new
    @active_nav = "registration"
    redirect_to new_user_session_path if current_account.present?
    @account = Account.new plan: params[:plan]
    @account.users.build
    render layout: "landing_page"
  end

  def create
    @active_nav = "registration"
    if account.save
      redirect_to new_user_session_path, flash: {success: resource_message(:account, :create, :success)}
    else
      render "new", alert: resource_message(:account, :create, :failure), layout: "landing_page"
    end
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

  private def check_registration_setting
    return if registration_enabled? || params[:stripe_test].present?

    redirect_to root_path
  end
end
