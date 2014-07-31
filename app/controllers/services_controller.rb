require 'dropbox_sdk'

class ServicesController < ApplicationController
  skip_authorization_check

  def dropbox
    authorize_url = dropbox_flow.start()
    redirect_to authorize_url
  end

  def activate_dropbox
    # begin
      access_token, user_id = dropbox_flow.finish(params)

      current_user.dropbox_token = access_token
      current_user.dropbox_user = user_id
      current_user.save

      redirect_to edit_user_registration_path, notice: I18n.t(:"messages.services.dropbox.success")
    # rescue
    #   redirect_to edit_user_registration_path, alert: I18n.t(:"messages.services.dropbox.failure")
    # end
  end

  def gdrive
  end

  private

  def dropbox_flow
    @dropbox_flow ||= DropboxOAuth2Flow.new(
      Settings.services.dropbox_key,
      Settings.services.dropbox_secret,
      "http://localhost:8240#{activate_dropbox_path}",
      session,
      :dropbox_auth_csrf_token,
      I18n.locale.to_s
    )
  end
end
