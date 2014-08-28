module Backend
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]
    before_action :set_active_nav

    # get: /backend/users
    def index
      @users = User.all
        .order(sort_column + " " + sort_direction)
        .page(params.fetch(:page){nil})
        .per(20)
    end

    # get: /backend/users/new
    def new
      @user = User.new
    end

    # post: /backend/users
    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to backend_users_path, notice: I18n.t(:"messages.user.create.success")
      else
        render 'new', error: I18n.t(:"messages.user.create.failure")
      end
    end

    # get: /backend/users/:id/edit
    def edit
    end

    # patch: /backend/users/:id
    def update
      if @user.update(user_params)
        redirect_to backend_users_path, notice: I18n.t(:"messages.user.create.success")
      else
        render "edit", error: I18n.t(:"messages.user.update.failure")
      end
    end

    def destroy
      if @user.destroy
        redirect_to backend_users_path, notice: I18n.t(:"messages.user.destroy.success")
      else
        redirect_to backend_users_path, error: I18n.t(:"messages.user.destroy.failure")
      end
    end

    def sort_column
      (User.column_names).include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private

    def user_params
      params.require(:user).permit(:email, :admin, :enabled)
    end

    def set_user
      @user = User.find(params[:id])
    end

    def set_active_nav
      @active_nav = 'backend_users'
    end
  end
end
