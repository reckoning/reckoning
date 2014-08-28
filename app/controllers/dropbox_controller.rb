require 'dropbox_sdk'

class DropboxController < ApplicationController
  skip_authorization_check

  DROPBOX_EXCEPTIONS = [
    DropboxOAuth2Flow::BadRequestError,
    DropboxOAuth2Flow::BadStateError,
    DropboxOAuth2Flow::CsrfError,
    DropboxOAuth2Flow::NotApprovedError,
    DropboxOAuth2Flow::ProviderError,
    DropboxError
  ]

  def start
    authorize_url = flow.start()
    redirect_to authorize_url
  end

  def activate
    begin
      access_token, user_id = flow.finish(params)

      current_user.dropbox_token = access_token
      current_user.dropbox_user = user_id
      current_user.save

      redirect_to edit_user_registration_path, notice: I18n.t(:"messages.dropbox.activate.success")
    rescue *DROPBOX_EXCEPTIONS
      redirect_to edit_user_registration_path, alert: I18n.t(:"messages.dropbox.activate.failure")
    end
  end

  def deactivate
    begin
      client = DropboxClient.new(current_user.dropbox_token)
      client.disable_access_token

      current_user.dropbox_token = nil
      current_user.dropbox_user = nil
      current_user.save

      redirect_to edit_user_registration_path, notice: I18n.t(:"messages.dropbox.deactivate.success")
    rescue => e
      redirect_to edit_user_registration_path, alert: I18n.t(:"messages.dropbox.deactivate.failure")
    end
  end

  private

  def flow
    @flow ||= DropboxOAuth2Flow.new(
      Rails.application.secrets[:dropbox_key],
      Rails.application.secrets[:dropbox_secret],
      activate_dropbox_url,
      session,
      :dropbox_auth_csrf_token,
      I18n.locale.to_s
    )
  end
end
