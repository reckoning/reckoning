# frozen_string_literal: true

require 'dropbox_sdk'

class DropboxController < ApplicationController
  DROPBOX_EXCEPTIONS = [
    DropboxOAuth2Flow::BadRequestError,
    DropboxOAuth2Flow::BadStateError,
    DropboxOAuth2Flow::CsrfError,
    DropboxOAuth2Flow::NotApprovedError,
    DropboxOAuth2Flow::ProviderError,
    DropboxError
  ].freeze

  def show
    @active_nav = "account"
    authorize! :connect, :dropbox
  end

  def start
    authorize! :connect, :dropbox
    authorize_url = flow.start
    redirect_to authorize_url
  end

  def activate
    authorize! :connect, :dropbox
    begin
      access_token, user_id = flow.finish(params)

      current_account.dropbox_token = access_token
      current_account.dropbox_user = user_id
      current_account.save

      redirect_to "#{edit_account_path}#{hash}", flash: { success: I18n.t(:"messages.dropbox.activate.success") }
    rescue *DROPBOX_EXCEPTIONS
      redirect_to "#{edit_account_path}#{hash}", alert: I18n.t(:"messages.dropbox.activate.failure")
    end
  end

  def deactivate
    authorize! :connect, :dropbox
    begin
      client = DropboxClient.new(current_account.dropbox_token)
      client.disable_access_token

      current_account.dropbox_token = nil
      current_account.dropbox_user = nil
      current_account.save

      redirect_to "#{edit_account_path}#{hash}", flash: { success: I18n.t(:"messages.dropbox.deactivate.success") }
    rescue StandardError
      redirect_to "#{edit_account_path}#{hash}", alert: I18n.t(:"messages.dropbox.deactivate.failure")
    end
  end

  private def hash
    params.fetch(:hash, "")
  end

  private def flow
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
