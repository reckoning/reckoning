# frozen_string_literal: true
ActionDispatch::Request.parameter_parsers[Mime[:json].symbol] = lambda do |raw_post|
  data = ActiveSupport::JSON.decode(raw_post)
  data = { _json: data } unless data.is_a?(Hash)
  data.deep_transform_keys!(&:underscore)
end
