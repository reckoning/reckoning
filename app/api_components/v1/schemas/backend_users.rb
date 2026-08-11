# frozen_string_literal: true

module V1
  module Schemas
    class BackendUsers
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::BackendUser})
    end
  end
end
