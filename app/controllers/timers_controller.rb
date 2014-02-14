class TimersController < ApplicationController
  before_filter :set_active_nav

  def index
    authorize! :index, :timers
    @date = date
  end

  private def set_active_nav
    @active_nav = 'timers'
  end

  private def week
    @week ||= current_user.weeks.where(start_date: date.beginning_of_week).first
    @week ||= current_user.weeks.new
  end
  helper_method :week

  private def date
    params[:date] ? Date.parse(params[:date]) : Date.today
  end
end
