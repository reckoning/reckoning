class RegistrationsController < Devise::RegistrationsController
  before_action :set_user, only: [:edit, :update]

  def edit
    @active_nav = 'user'
    authorize! :update, @user
  end

  def update
    @active_nav = 'user'
    authorize! :update, @user
    if @user.update_without_password(user_params)
      redirect_to "#{edit_user_registration_path}#{hash}", flash: { success: I18n.t(:"messages.registration.update.success") }
    else
      render "edit#{hash}", alert: I18n.t(:"messages.registration.update.failure")
    end
  end

  private def user_params
    @user_params ||= params.require(:user).permit(
      :email, :gravatar, :remember_me, :name, :layout
    )
  end

  private def set_user
    @user = current_user
  end

  private def hash
    params.fetch(:hash, "")
  end
end
