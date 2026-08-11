# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class TaskInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1},
            project_id: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[name project_id]
        })
      end
    end
  end
end
