# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class TimerInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # camelCase, like the rest of the wire format: every client sends
            # `taskId`, and `Api::BaseController#openapi_params` underscores it
            # on the way in. Declared as `task_id` this validated nothing and
            # warned on every timer written.
            taskId: {type: :string, format: :uuid},
            date: {type: :string, format: :date},
            value: {type: [:string, :number]},
            note: {type: [:string, :null]},
            started: {type: :boolean, description: "Start the timer immediately after saving."}
          },
          additionalProperties: false,
          required: %w[taskId]
        })
      end
    end
  end
end
