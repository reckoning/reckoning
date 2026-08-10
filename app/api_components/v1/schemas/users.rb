# frozen_string_literal: true

module V1
  module Schemas
    class Users
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::User})
    end
  end
end
