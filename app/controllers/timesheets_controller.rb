class TimesheetsController < ApplicationController
  before_action :set_active_nav

  def show
    authorize! :show, :timesheet
  end

  def week
    authorize! :week, :timesheet
    render "week", layout: false
  end

  def day
    authorize! :day, :timesheet
    render "day", layout: false
  end

  def task_modal
    authorize! :task_modal, :timesheet
    render "task_modal", layout: false
  end

  def timer_modal
    authorize! :timer_modal, :timesheet
    render "timer_modal", layout: false
  end

  def new_import
    authorize! :new_import, Timer
  end

  def csv_import
    authorize! :csv_import, Timer
    if Timer.import(params[:timer][:file], params[:timer][:project_id])
      redirect_to timers_path, flash: { success: I18n.t(:"messages.timer.import.success") }
    else
      redirect_to timers_path, alert: I18n.t(:"messages.timer.import.failure")
    end
  end

  private def set_active_nav
    @active_nav = 'timesheet'
  end
end
