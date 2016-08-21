# frozen_string_literal: true
class LogbooksController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def show
    authorize! :read, :logbook
    @vessels = Vessel.where(account_id: current_account.id)
    @tours = Tour.where(account_id: current_account.id)
  end

  private def set_active_nav
    @active_nav = 'logbook'
  end
end
