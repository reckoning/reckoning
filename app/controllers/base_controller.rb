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
    @timers_chart_data = generate_timers_chart_data
    @invoices_chart_data, @invoices_max_value, @invoices_max_month_value = generate_invoices_chart_data
    render 'dashboard'
  end

  def welcome
    @active_nav = 'welcome'
    render 'welcome'
  end

  def generate_timers_chart_data
    result = []
    start_date = Date.today - 1.month
    end_date = Date.today
    current_user.projects.each do |project|
      chart = {key: project.name, values: []}
      if project.timers.where(date: start_date..end_date).present?
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

  def generate_invoices_chart_data
    result = []
    sum = {key: I18n.t(:"labels.chart.invoices.sum"), values: []}
    month = {key: I18n.t(:"labels.chart.invoices.month"), values: []}
    last_value = 0.0
    max_month_value = 0.0
    (1..12).each do |month_id|
      start_date = Date.parse("#{Date.today.year}-#{month_id}-1").at_beginning_of_month
      end_date = Date.parse("#{Date.today.year}-#{month_id}-1").at_end_of_month

      value = 0.0
      current_user.invoices.where(date: start_date..end_date).all.each do |invoice|
        value += invoice.value.to_d
      end

      if value.zero?
        month_value = sum_value = nil
      else
        month_value = value
        last_value = sum_value = (last_value + value.to_f)
      end

      month[:values] << [(start_date.to_time.to_i * 1000), month_value]
      sum[:values] << [(start_date.to_time.to_i * 1000), sum_value]

      if max_month_value < value.to_f
        max_month_value = value.to_f
      end
    end
    result << month
    result << sum
    return result, last_value, max_month_value
  end
end
