class WeeksController < ApplicationController

  def create
    authorize! :create, week
    if week.save
      redirect_to timers_path(date: week.start_date)
    else
      redirect_to timers_path(date: week.start_date)
    end
  end

  def update
    authorize! :update, week
    if week.update(week_params)
      redirect_to timers_path(date: week.start_date)
    else
      redirect_to timers_path(date: week.start_date)
    end
  end

  def add_task
    authorize! :add_task, week
    respond_to do |format|
      format.js {
        task = current_user.tasks.where(id: params.fetch(:task_id, nil)).first
        if task.present? && !week.tasks.include?(task)
          week.tasks << task
          week.save
          flash[:notice] = I18n.t(:"messages.timesheet.add_task.success")
        end
        render json: task
      }
      format.html {
        redirect_to timers_path
      }
    end
  end

  def remove_task
    authorize! :remove_task, week
    task = current_user.tasks.where(id: params.fetch(:task_id, nil)).first
    if task.present? && week.tasks.include?(task)
      week.timers.where(task_id: task.id, position_id: nil).destroy_all
      if task.timers.with_positions.empty?
        week.tasks.delete(task)
        redirect_to timers_path(date: week.start_date), notice: I18n.t(:"messages.timesheet.remove_task.success")
      else
        redirect_to timers_path(date: week.start_date), warning: I18n.t(:"messages.timesheet.remove_task.warning")
      end
    else
      redirect_to timers_path(date: week.start_date), error: I18n.t(:"messages.timesheet.remove_task.failure")
    end
  end

  private def week_params
    @week_params ||= params.require(:week).permit(
      :start_date,
      timers_attributes: [
        :id,
        :task_id,
        :value,
        :date
      ]
    )
  end

  private def week
    @week ||= current_user.weeks.where(id: params.fetch(:id, nil)).first
    @week ||= current_user.weeks.where(start_date: params.fetch(:week, {}).fetch(:start_date, nil)).first
    week_params.fetch(:timers_attributes, {}).reject! {|index, timer| timer[:value].empty? } unless @week.present?
    @week ||= current_user.weeks.new week_params
  end
end
