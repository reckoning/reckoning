class TimersController < ApplicationController
  def uninvoiced
    authorize! :index, Timer
    respond_to do |format|
      format.js do
        scope = current_account.timers.uninvoiced
        scope = scope.for_project(project_uuid) if project_uuid
        scope = scope.without(timer_uuids) if timer_uuids
        timers = scope.order(date: :asc)
        render json: { body: render_to_string(partial: "list", locals: { timers: timers }) }
      end
      format.html { redirect_to root_path }
    end
  end

  private def project_uuid
    @project_uuid ||= params[:project_uuid]
  end

  private def timer_uuids
    @timer_uuids ||= params[:timer_uuids]
  end
end
