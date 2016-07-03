# encoding: utf-8
# frozen_string_literal: true
class TimesheetsController < ApplicationController
  before_action :set_active_nav

  def show
    authorize! :show, :timesheet
  end

  def week_template
    authorize! :week, :timesheet
    render "week_template", layout: false
  end

  def day_template
    authorize! :day, :timesheet
    render "day_template", layout: false
  end

  def task_modal_template
    authorize! :task_modal, :timesheet
    render "task_modal_template", layout: false
  end

  def timer_modal_template
    authorize! :timer_modal, :timesheet
    render "timer_modal_template", layout: false
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
