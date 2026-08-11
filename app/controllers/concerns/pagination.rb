# frozen_string_literal: true

# Cursorless pagination for the JSON API, ported from FleetYards.
#
# List responses stay bare arrays — the page metadata travels in a `Link`
# header (RFC 8288). That keeps the generated TS types clean: a list endpoint
# returns `Customer[]`, not an envelope the caller has to unwrap.
module Pagination
  class MaxPerPageReached < StandardError; end

  DEFAULT_MAX_PER_PAGE = 100

  private def paginate(scope)
    return scope.all if all_records_requested?

    scope.page(params[:page]).per(per_page(scope))
  end

  # Call from an `after_action` once the collection ivar is set.
  private def pagination_header(name)
    return if response.status >= 400

    scope = instance_variable_get(:"@#{name}")
    links = {self: page_link(nil)}
    links = links.merge(pagination_links(scope)) if scope.present? && !all_records_requested?

    headers["Link"] = links.filter_map { |rel, url| "<#{url}>; rel=\"#{rel}\"" if url.present? }.join(", ")
  end

  private def per_page(scope)
    model = scope.respond_to?(:model) ? scope.model : scope
    return model.default_per_page if per_page_param.blank? || per_page_param.to_i.zero?

    max = model.max_per_page || DEFAULT_MAX_PER_PAGE
    raise MaxPerPageReached if per_page_param.to_i > max

    per_page_param.to_i
  end

  private def pagination_links(scope)
    # `all` skipped kaminari, so there are no page boundaries to describe.
    return {} unless scope.respond_to?(:current_page)

    {
      first: page_link(1),
      next: (page_link(scope.current_page + 1) unless scope.last_page?),
      prev: (page_link(scope.current_page - 1) unless scope.first_page?),
      last: page_link(scope.total_pages)
    }
  end

  private def page_link(page)
    url_for(
      controller: controller_path,
      action: action_name,
      page: page,
      perPage: per_page_param.presence,
      only_path: true
    )
  end

  private def all_records_requested?
    per_page_param == "all"
  end

  private def per_page_param
    @per_page_param ||= params[:perPage] || params[:per_page]
  end
end
