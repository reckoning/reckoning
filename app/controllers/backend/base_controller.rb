module Backend

  class BaseController < ApplicationController
    before_filter :verify_admin

    skip_authorization_check

    def dashboard
      @active_nav = 'backend_dashboard'
      @settings = Rails.application.secrets
      @latest_users = User.limit(10).order('created_at DESC')
      @latest_contacts = Contact.limit(10).order('created_at DESC')
      @users_count = User.count
      @contacts_count = Contact.count
    end

    private

    def verify_admin
      redirect_to root_url unless current_user.try(:admin?)
    end
  end
end
