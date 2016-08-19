# encoding: utf-8
# frozen_string_literal: true
module Backend
  class AccountsController < BaseController
    include ResourceHelper

    before_action :set_active_nav

    # get: /backend/accounts
    def index
      @accounts = Account.all
                         .order(created_at: :desc)
                         .page(params.fetch(:page) { nil })
                         .per(20)
    end

    # get: /backend/accounts/new
    def new
      @account = Account.new
      account.users.build
    end

    # post: /backend/accounts
    def create
      generated_password = Devise.friendly_token.first(16)
      user = account.users.first
      user.created_via_admin = true
      user.password = generated_password
      user.password_confirmation = generated_password
      if account.save
        redirect_to backend_accounts_path, notice: resource_message(:account, :create, :success)
      else
        render 'new', error: resource_message(:account, :create, :failure)
      end
    end

    # get: /backend/accounts/:id/edit
    def edit
    end

    # patch: /backend/accounts/:id
    def update
      if account.update(account_params)
        redirect_to backend_accounts_path, notice: resource_message(:account, :update, :success)
      else
        render "edit", error: resource_message(:account, :update, :failure)
      end
    end

    def destroy
      if account.destroy
        redirect_to backend_accounts_path, notice: resource_message(:account, :destroy, :success)
      else
        redirect_to backend_accounts_path, error: resource_message(:account, :destroy, :failure)
      end
    end

    private def account_params
      params.require(:account).permit(:plan, :name, :feature_expenses, :feature_logbook, users_attributes: [:email])
    end

    private def account
      @account ||= Account.where(id: params.fetch(:id, nil)).first
      @account ||= Account.new(account_params)
    end
    helper_method :account

    private def set_active_nav
      @active_nav = "backend_accounts"
    end
  end
end
