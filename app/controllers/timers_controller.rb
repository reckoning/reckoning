# frozen_string_literal: true

class TimersController < ApplicationController
  def uninvoiced
    authorize! :index, Timer
    respond_to do |format|
      format.js do
        scope = current_account.timers.uninvoiced.billable
        scope = scope.for_project(project_id) if project_id
        scope = scope.without_ids(timer_ids) if timer_ids
        timers = scope.order(date: :asc)
        render json: { body: render_to_string(partial: "list", locals: { timers: timers }) }
      end
      format.html { redirect_to root_path }
    end
  end

  private def project_id
    @project_id ||= params[:projectId]
  end

  private def timer_ids
    @timer_ids ||= params[:timerIds]
  end
end
