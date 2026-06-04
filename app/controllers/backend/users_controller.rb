# frozen_string_literal: true

module Backend
  class UsersController < BaseController
    include ResourceHelper

    before_action :set_active_nav

    # get: /backend/users
    def index
      @users = User.all
        .order("#{sort_column} #{sort_direction}")
        .page(params.fetch(:page, nil))
        .per(20)
    end

    # get: /backend/users/new
    def new
    end

    # post: /backend/users
    def edit
    end

    def send_welcome
      if user.send_confirmation_instructions
        redirect_to backend_users_path, notice: I18n.t(:"messages.user.send_welcome.success")
      else
        redirect_to backend_users_path, notice: I18n.t(:"messages.user.send_welcome.failure")
      end
    end

    # get: /backend/users/:id/edit
    def create
      password = Devise.friendly_token.first(30)
      @user = User.new(
        user_params.merge(
          password: password,
          password_confirmation: password
        )
      )
      user.skip_confirmation_notification!
      if user.save
        redirect_to backend_users_path, notice: resource_message(:user, :create, :success)
      else
        render "new", error: resource_message(:user, :create, :failure)
      end
    end

    # patch: /backend/users/:id
    def update
      if user.update(user_params)
        redirect_to backend_users_path, notice: resource_message(:user, :update, :success)
      else
        render "edit", error: resource_message(:user, :update, :failure)
      end
    end

    def destroy
      if user.destroy
        redirect_to backend_users_path, notice: resource_message(:user, :destroy, :success)
      else
        redirect_to backend_users_path, error: resource_message(:user, :destroy, :failure)
      end
    end

    def sort_column
      User.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private def user_params
      # Only admins can promote/demote other admins. Brakeman flags any
      # unconditional `permit(:admin)`; gating the key on the current
      # user's role both satisfies the check and tightens the actual
      # authorization story (the /backend namespace is also gated at
      # the route level by Warden, but defense in depth).
      permitted = [:email, :password, :password_confirmation, :enabled]
      permitted << :admin if current_user&.admin?
      params.require(:user).permit(*permitted)
    end

    private def user
      @user ||= User.where(id: params.fetch(:id, nil)).first
      @user ||= User.new
    end
    helper_method :user

    private def set_active_nav
      @active_nav = "backend_users"
    end
  end
end
