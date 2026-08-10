# frozen_string_literal: true

module V1
  module Schemas
    class Invoices
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::Invoice})
    end
  end
end
