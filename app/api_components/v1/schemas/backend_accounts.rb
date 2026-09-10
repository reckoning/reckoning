# frozen_string_literal: true

module V1
  module Schemas
    class BackendAccounts
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::BackendAccount})
    end
  end
end
