module ApplicationHelper
  def invoice_label(invoice)
    case invoice.state
    when "created"
      "default"
    when "paid"
      "success"
    else
      "primary"
    end
  end

  def first_invoice_year
    first_invoice = current_account.invoices.order('date').first
    return unless first_invoice.present?
    first_invoice.date.year
  end

  def current_years
    current_year = Time.now.year
    current_year = (Time.now + 1.year).year if Time.now.month == 12
    if first_invoice_year
      years = (first_invoice_year..current_year)
    else
      years = ((Time.now - 1.year).year..current_year)
    end
    years.to_a.reverse.map do |year|
      { name: year, link: year }
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, plumb(sort: column, direction: direction, page: nil), class: css_class
  end

  def gravatar_path(size = 20, hash = nil)
    hash ||= current_user.gravatar_hash
    "//www.gravatar.com/avatar/#{hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{hash}.png&amp;r=x&amp;s=#{size}"
  end
end
