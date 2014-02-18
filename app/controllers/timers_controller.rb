class TimersController < ApplicationController
  before_filter :set_active_nav

  def index
    authorize! :index, Timer
    @date = date
  end

  def import
    authorize! :import, Timer
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
    @date ||= (params[:date].present? ? Date.parse(params.fetch(:date, nil)) : Date.today)
  end
end
