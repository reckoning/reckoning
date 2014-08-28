module ApplicationHelper

  def invoice_label invoice
    case invoice.state
    when "created"
      "default"
    when "paid"
      "success"
    else
      "primary"
    end
  end

  def current_years
    years = [{name: Time.now.year - 1, link: Time.now.year - 1}, {name: Time.now.year, link: Time.now.year}]
    years << {name: Time.now.year + 1, link: Time.now.year + 1} if Time.now.month == 12
    years.reverse
  end

  def sortable column, title = nil, remote = true
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, plumb(sort: column, direction: direction, page: nil), {:class => css_class}
  end

  def gravatar_path size = 20, hash = nil
    hash ||= current_user.gravatar_hash
    "//www.gravatar.com/avatar/#{hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{hash}.png&amp;r=x&amp;s=#{size}"
  end

end
