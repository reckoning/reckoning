class RegistrationsController < Devise::RegistrationsController
  before_action :set_user, only: [:edit, :update]
  before_action :check_registration_setting, only: [:new, :create]

  def new
    @active_nav = 'registration'
    @user = User.new
  end

  def edit
    @active_nav = 'users'
    authorize! :update, @user
  end

  def update
    @active_nav = 'users'
    authorize! :update, @user
    if @user.update_without_password(user_params)
      redirect_to edit_user_registration_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.user_data"))
    else
      render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.user_data"))
    end
  end

  private

  def user_params
    @user_params ||= params.require(:user).permit(
      :plan,
      :email,
      :gravatar,
      :remember_me,
      :tax, :tax_ref,
      :provision,
      :gdrive_email, :gdrive_password, :gdrive_collection,
      :bank, :account_number, :bank_code, :bic, :iban,
      :default_from, :signature,
      address_attributes: [
        :company,
        :name,
        :address,
        :country,
        :email,
        :telefon,
        :fax,
        :website
      ]
    )
  end

  def set_user
    @user = current_user
  end

  def check_registration_setting
    unless registration_enabled?
      redirect_to root_path
    end
  end
end
