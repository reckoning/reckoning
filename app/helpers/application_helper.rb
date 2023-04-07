# frozen_string_literal: true

require "json_web_token"

module ApplicationHelper
  def main_title
    [
      ("#{current_account.name} -" if defined?(current_account) && current_account.present?),
      I18n.t(:"meta.title.default")
    ].compact.join(" ")
  end

  def auth_token
    @auth_token ||= if user_signed_in?
      JsonWebToken.encode(
        exp: Time.zone.now.to_i + Rails.configuration.app.jwt_expiration,
        user_id: current_user.id
      )
    else
      ""
    end
  end

  def title(label = nil)
    [
      label,
      main_title
    ].compact.join(" | ")
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, plumb(sort: column, direction: direction, page: nil), class: css_class
  end

  def overtime_label(overtime, weekly_hours)
    hours_per_day = weekly_hours / 5
    if overtime < (hours_per_day * 1.25) && overtime > (hours_per_day * -1.25)
      "success"
    elsif overtime < (hours_per_day * 2.5) && overtime > (hours_per_day * -2.5)
      "warning"
    else
      "danger"
    end
  end

  def weekly_hours_label(weekly_hours)
    # TODO: move to db field
    default_work_hours = 40

    if weekly_hours < (default_work_hours * 1.25) && weekly_hours > (default_work_hours * -1.25)
      "success"
    elsif weekly_hours < (default_work_hours * 2.5) && weekly_hours > (default_work_hours * -2.5)
      "warning"
    else
      "danger"
    end
  end

  def daily_hours_label(daily_hours)
    # TODO: move to db field
    default_work_hours = 8

    if daily_hours < (default_work_hours * 1.25) && daily_hours > (default_work_hours * -1.25)
      "success"
    elsif daily_hours < (default_work_hours * 2.5) && daily_hours > (default_work_hours * -2.5)
      "warning"
    else
      "danger"
    end
  end
end
