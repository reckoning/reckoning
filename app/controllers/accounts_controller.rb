class AccountsController < ApplicationController
  before_action :check_registration_setting, only: [:new, :create]
  before_action :set_active_nav, except: [:new, :create]
  before_action :authenticate_user!, except: [:new, :create]
  skip_authorization_check only: [:new, :create]

  def new
    @active_nav = 'registration'
    redirect_to new_user_session_path if current_account.present?
    @account = Account.new plan: params[:plan]
    @account.users.build
  end

  def create
    @active_nav = 'registration'
    if account.save
      redirect_to new_user_session_path, flash: { success: I18n.t(:"messages.account.create.success") }
    else
      render "new", alert: I18n.t(:"messages.account.create.failure")
    end
  end

  def edit
    authorize! :update, account
  end

  def update
    authorize! :update, account
    if account.update(account_params)
      redirect_to "#{edit_account_path}#{hash}", flash: { success: I18n.t(:"messages.account.update.success") }
    else
      render "edit", alert: I18n.t(:"messages.account.update.failure")
    end
  end

  private def set_active_nav
    @active_nav = 'account'
  end

  private def account_params
    @account_params ||= params.require(:account).permit(
      :plan,
      :tax,
      :tax_ref,
      :provision,
      :bank,
      :account_number,
      :bank_code,
      :bic,
      :iban,
      :default_from,
      :signature,
      :name,
      :address,
      :country,
      :public_email,
      :subdomain,
      :telefon,
      :fax,
      :website,
      :stripe_email,
      :stripe_token,
      users_attributes: [:email, :password, :password_confirmation]
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
