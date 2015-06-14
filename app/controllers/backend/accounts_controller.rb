module Backend
  class AccountsController < BaseController
    include ResourceHelper

    before_action :set_active_nav

    # get: /backend/accounts
    def index
      @accounts = Account.all
                  .order("#{sort_column} #{sort_direction}")
                  .page(params.fetch(:page) { nil })
                  .per(20)
    end

    # get: /backend/accounts/new
    def new
    end

    # post: /backend/accounts
    def create
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

    def sort_column
      (Account.column_names).include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private

    def account_params
      params.require(:account).permit(:name)
    end

    def account
      @account ||= Account.where(id: params.fetch(:id, nil)).first
      @account ||= Account.new
    end
    helper_method :account

    def set_active_nav
      @active_nav = 'backend_accounts'
    end
  end
end
