# frozen_string_literal: true

module V1
  module Schemas
    class Offers
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::Offer})
    end
  end
end
