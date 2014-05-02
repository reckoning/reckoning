class PasswordsController < ApplicationController
  before_action :set_user, only: [:edit, :update]
  before_action :set_active_nav

  def edit
    authorize! :update, @user
  end

  def update
    authorize! :update, @user
    if @user.update_with_password(password_params)
      redirect_to edit_user_registration_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.password"))
    else
      render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.password"))
    end
  end

  private

  def set_active_nav
    @active_nav = 'users'
  end

  def password_params
    @password_params ||= params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

  def set_user
    @user = current_user
  end
end
