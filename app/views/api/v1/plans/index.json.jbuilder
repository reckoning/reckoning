# frozen_string_literal: true

json.array! @plans do |plan|
  json.id plan.id
  json.code plan.code
  json.name plan.name
  json.price plan.price.cents
  json.quantity plan.quantity
  json.interval plan.interval
  json.featured plan.featured
  # `plans.desc.<code>` is a hash of lines; the page prints its values.
  json.descriptions Array(I18n.t("plans.desc.#{plan.code}", default: {}).values).map(&:to_s)
end
