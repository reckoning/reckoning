module ApplicationHelper
  def main_title
    [
      ("#{current_account.name} -" if defined?(current_account) && current_account.present?),
      I18n.t(:"meta.title.default")
    ].compact.join(" ")
  end

  def auth_token
    if defined?(current_user) && user_signed_in?
      "#{current_user.id}:#{current_user.authentication_token}"
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
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, plumb(sort: column, direction: direction, page: nil), class: css_class
  end

  def gravatar_path(size = 24, hash = nil)
    hash ||= current_user.gravatar_hash
    "//www.gravatar.com/avatar/#{hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{hash}.png&amp;r=x&amp;s=#{size}"
  end
end
