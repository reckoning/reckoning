module Backend
  class BaseController < ApplicationController
    before_action :verify_admin
    layout 'backend'

    skip_authorization_check

    def dashboard
      @active_nav = 'backend_dashboard'
      @settings = Rails.application.secrets
    end

    private def verify_admin
      redirect_to root_url unless current_user.try(:admin?)
    end
  end
end
