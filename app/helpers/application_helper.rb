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
    current_year = Time.now.year
    if Time.now.month == 12
      current_year = (Time.now + 1.year).year
    end
    if start_year = Invoice.start_year
      years = (start_year..current_year)
    else
      years = ((Time.now - 1.years).year..current_year)
    end
    years.to_a.reverse.map do |year|
      {name: year, link: year}
    end
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
