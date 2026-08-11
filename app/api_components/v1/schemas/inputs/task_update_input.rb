# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class TaskUpdateInput
        include OpenapiRuby::Components::Base

        # No project_id: moving a task between projects would re-home its
        # timers, which is not something the UI offers.
        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1},
            billable: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
