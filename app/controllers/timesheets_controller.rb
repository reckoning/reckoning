# frozen_string_literal: true

class TimesheetsController < ApplicationController
  before_action :set_active_nav

  def show
    authorize! :show, :timesheet
  end

  private def set_active_nav
    @active_nav = "timesheet"
  end
end
