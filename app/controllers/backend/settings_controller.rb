module Backend
  class SettingsController < BaseController
    before_action :set_setting, only: [:edit, :update, :destroy]
    before_action :set_keypath
    before_action :set_default_setting

    def new
      @setting = Setting.new(keypath: @keypath)
      render "edit"
    end

    def create
      @setting = Setting.new(setting_params)
      if @setting.save
        Settings.merge(Setting.to_h)
        redirect_to backend_root_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.setting"))
      else
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.setting"))
      end
    end

    # get: /backend/settings/:id/edit
    def edit
    end

    def update
      if @setting.update(setting_params)
        Settings.merge(Setting.to_h)
        redirect_to backend_root_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.setting"))
      else
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.setting"))
      end
    end

    def destroy
      if @setting.destroy
        Settings.reset @keypath, DefaultSettings.find(@keypath)
        redirect_to backend_root_path, notice: I18n.t(:"messages.destroy.setting.success", resource: I18n.t(:"resources.messages.setting"))
      else
        redirect_to backend_root_path, error: I18n.t(:"messages.destroy.setting.success", resource: I18n.t(:"resources.messages.setting"))
      end
    end

    private

    def setting_params
      params.require(:setting).permit(:keypath, :value)
    end

    def set_keypath
      @keypath = params.fetch(:keypath, nil)
      @keypath ||= params.fetch(:setting, {}).fetch(:keypath, nil)
      @keypath ||= @setting.keypath if @setting.present?
      unless Settings.check_path?(@keypath)
        redirect_to backend_root_path, warning: I18n.t("messages.setting.not_found")
        return
      end
    end

    def set_setting
      @setting = Setting.find(params[:id])
    end

    def set_default_setting
      @default_setting = DefaultSettings.find(@keypath) if @keypath.present?
      @default_setting ||= DefaultSettings.find(@setting.keypath) if @setting.present?
    end
  end
end
