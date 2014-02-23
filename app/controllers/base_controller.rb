class BaseController < ApplicationController
  skip_authorization_check
  before_filter :authenticate_user!, :only => [:fail]

  def index
    if user_signed_in?
      dashboard
    else
      welcome
    end
  end

  def dashboard
    @charged_invoices = current_user.invoices.order('date DESC').charged
    @paid_invoices = current_user.invoices.order('date DESC').paid.year(Time.now.year)
    @last_invoices = current_user.invoices.order('date DESC').paid.year(Time.now.year - 1)
    @budgets = current_user.projects.with_budget.includes(:tasks).order('tasks.updated_at DESC')
    @chart_data = generate_timer_chart_data

    render 'dashboard'
  end

  def welcome
    @active_nav = 'welcome'
    render 'welcome'
  end

  def generate_timer_chart_data
    result = []
    start_date = Date.today - 1.month
    end_date = Date.today
    current_user.projects.each do |project|
      chart = {key: project.name, values: []}
      if project.timers.present?
        (start_date..end_date).each do |date|
          timers = current_user.timers.includes(:task).where(date: date, "tasks.project_id" => project.id).references(:task).all
          value = 0.0
          timers.each do |timer|
            value += timer.value.to_d
          end
          chart[:values] << {x: I18n.l(date, format: :db), y: value.to_f}
        end
        result << chart
      end
    end
    return result
  end
end
