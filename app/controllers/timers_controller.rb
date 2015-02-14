class TimersController < ApplicationController
  before_action :set_active_nav

  def index
    authorize! :index, Timer
    @date = date
    projects = current_account.projects.order("created_at DESC")
    @projects = projects.active.all
  end

  def new_import
    authorize! :new_import, Timer
  end

  def csv_import
    authorize! :csv_import, Timer
    if Timer.import(params[:timer][:file], params[:timer][:project_id])
      redirect_to timers_path, success: I18n.t(:"messages.timer.import.success")
    else
      redirect_to timers_path, alert: I18n.t(:"messages.timer.import.failure")
    end
  end

  private

  def set_active_nav
    @active_nav = 'timers'
  end

  def week
    @week ||= current_account.weeks.where(start_date: date.beginning_of_week).first
    @week ||= current_account.weeks.new
  end
  helper_method :week

  def date
    @date ||= (params[:date].present? ? Date.parse(params.fetch(:date, nil)) : Date.today)
  end
end
