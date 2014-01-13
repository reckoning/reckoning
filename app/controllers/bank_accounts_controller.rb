class BankAccountsController < ApplicationController
  before_filter :set_active_nav

  def edit
    authorize! :update, user
  end

  def update
    authorize! :update, user
    if user.update_without_password(bank_accounts_params)
      redirect_to edit_bank_account_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.bank_account"))
    else
      render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.bank_account"))
    end
  end

  protected

  def set_active_nav
    @active_nav = 'bank_accounts'
  end

  helper_method :user

  def bank_accounts_params
    @bank_accounts_params ||= params.require(:user).permit(:bank, :account_number, :bank_code, :bic, :iban)
  end

  def user
    @user ||= current_user
  end

end
