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
            # `taskId`, and the JSON parameter parser installed in
            # `config/initializers/json_param_key_transform.rb` underscores it
            # on the way in — this controller permits params directly rather
            # than going through `openapi_params`. Declared as `task_id` the
            # schema validated nothing and warned on every timer written.
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
