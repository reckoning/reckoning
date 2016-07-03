class TimersController < ApplicationController
  def uninvoiced
    authorize! :index, Timer
    respond_to do |format|
      format.js do
        timers = current_account.timers.for_project(project_uuid).uninvoiced.order(date: :asc)
        render json: { body: render_to_string(partial: "list", locals: { timers: timers }) }
      end
      format.html { redirect_to root_path }
    end
  end

  private def project_uuid
    @project_uuid ||= params[:project_uuid]
  end
end
