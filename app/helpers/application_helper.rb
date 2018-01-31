# frozen_string_literal: true

module ApplicationHelper
  def main_title
    [
      ("#{current_account.name} -" if defined?(current_account) && current_account.present?),
      I18n.t(:"meta.title.default")
    ].compact.join(" ")
  end

  def auth_token
    @auth_token ||= begin
      if user_signed_in?
        JsonWebToken.encode(
          exp: Time.zone.now.to_i + Rails.application.secrets[:jwt_expiration],
          user_id: current_user.id
        )
      else
        ""
      end
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
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, plumb(sort: column, direction: direction, page: nil), class: css_class
  end

  def overtime_label(overtime, weekly_hours)
    hours_per_day = weekly_hours / 5
    if overtime < (hours_per_day * 1.25)
      "success"
    elsif overtime < (hours_per_day * 2.5)
      "warning"
    else
      "danger"
    end
  end
end
