module Backend
  class AccountsController < BaseController
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
        redirect_to backend_accounts_path, notice: I18n.t(:"messages.resource.create.success", resource: "Account")
      else
        render 'new', error: I18n.t(:"messages.resource.create.failure", resource: "Account")
      end
    end

    # get: /backend/accounts/:id/edit
    def edit
    end

    # patch: /backend/accounts/:id
    def update
      if account.update(account_params)
        redirect_to backend_accounts_path, notice: I18n.t(:"messages.resource.create.success", resource: "Account")
      else
        render "edit", error: I18n.t(:"messages.resource.update.failure", resource: "Account")
      end
    end

    def destroy
      if account.destroy
        redirect_to backend_accounts_path, notice: I18n.t(:"messages.resource.destroy.success", resource: "Account")
      else
        redirect_to backend_accounts_path, error: I18n.t(:"messages.resource.destroy.failure", resource: "Account")
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
