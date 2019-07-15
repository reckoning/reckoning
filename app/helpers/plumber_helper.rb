# frozen_string_literal: true

module PlumberHelper
  def plumb(attributes)
    # rubocop:disable Rails/HelperInstanceVariable
    url_for((@plumber ||= ::UrlPlumber::Plumber.new(params)).plumb(attributes))
    # rubocop:enable Rails/HelperInstanceVariable
  end
end
