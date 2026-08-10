# frozen_string_literal: true

module V1
  module Schemas
    class Expenses
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::Expense})
    end
  end
end
