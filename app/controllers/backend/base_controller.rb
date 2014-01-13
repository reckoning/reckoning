module Backend

  class BaseController < ApplicationController
    before_filter :verify_admin

    skip_authorization_check

    def dashboard
      @active_nav = 'backend_dashboard'
      @settings = Setting.all.to_h
    end

    private

    def verify_admin
      redirect_to root_url unless current_user.try(:admin?)
    end
  end
end
