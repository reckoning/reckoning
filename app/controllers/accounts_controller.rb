class AccountsController < ApplicationController
  before_action :set_active_nav

  def edit
    authorize! :update, account
  end

  def update
    authorize! :update, account
    if account.update_without_password(account_params)
      redirect_to "#{edit_account_path}#{hash}", notice: I18n.t(:"messages.account.update.success")
    else
      render "edit#{hash}", alert: I18n.t(:"messages.account.update.failure")
    end
  end

  private def set_active_nav
    @active_nav = 'account'
  end

  private def account_params
    @account_params ||= params.require(:account).permit(
      :plan, :tax, :tax_ref, :provision, :bank, :account_number,
      :bank_code, :bic, :iban, :default_from, :signature,
      :name, :address, :country, :public_email,
      :telefon, :fax, :website
    )
  end

  private def account
    @account = current_account
  end
  helper_method :account

  private def hash
    params.fetch(:hash, "")
  end
end
