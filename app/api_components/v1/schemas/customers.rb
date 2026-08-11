# frozen_string_literal: true

module V1
  module Schemas
    class Customers
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: V1::Schemas::Customer
      })
    end
  end
end
