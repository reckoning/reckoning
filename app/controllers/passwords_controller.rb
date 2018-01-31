# frozen_string_literal: true

class PasswordsController < ApplicationController
  before_action :set_user, only: %i[edit update]
  before_action :set_active_nav

  def edit
    authorize! :update, @user
  end

  def update
    authorize! :update, @user
    if @user.update_with_password(password_params)
      redirect_to "#{edit_user_registration_path}#security", flash: { success: I18n.t(:"messages.password.update.success") }
    else
      render "edit#security", alert: I18n.t(:"messages.password.update.failure")
    end
  end

  private def set_active_nav
    @active_nav = 'users'
  end

  private def password_params
    @password_params ||= params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

  private def set_user
    @user = current_user
  end
end
