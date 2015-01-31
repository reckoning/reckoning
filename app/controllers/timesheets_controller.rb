class TimesheetsController < ApplicationController
  before_action :set_active_nav

  def show
    authorize! :index, :timesheet
  end

  private
  def set_active_nav
    @active_nav = 'timesheet'
  end
end