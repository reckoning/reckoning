# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class TimerInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            task_id: {type: :string, format: :uuid},
            date: {type: :string, format: :date},
            value: {type: [:string, :number]},
            note: {type: [:string, :null]},
            started: {type: :boolean, description: "Start the timer immediately after saving."}
          },
          additionalProperties: false,
          required: %w[task_id]
        })
      end
    end
  end
end
