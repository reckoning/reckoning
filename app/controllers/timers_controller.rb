class TimersController < ApplicationController
  before_filter :set_active_nav

  def index
    authorize! :index, Timer
    @date = date
    projects = current_user.projects
    if week.projects.present?
      projects = projects.where("projects.id not in (?)", week.projects.map(&:id))
    end
    @projects = projects.all
  end

  def new_import
    authorize! :new_import, Timer
  end

  def csv_import
    authorize! :csv_import, Timer
    if Timer.import(params[:timer][:file], params[:timer][:project_id])
      redirect_to timers_path, notice: I18n.t(:"messages.import.success", resource: I18n.t(:"resources.messages.timers"))
    else
      redirect_to timers_path, error: I18n.t(:"messages.import.failure", resource: I18n.t(:"resources.messages.timers"))
    end
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
