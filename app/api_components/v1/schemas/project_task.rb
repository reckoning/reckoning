# frozen_string_literal: true

module V1
  module Schemas
    # A task as nested inside a project payload — no project back-references.
    class ProjectTask
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          label: {type: :string},
          billable: {type: :boolean},
          projectId: {type: :string, format: :uuid},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name projectId createdAt updatedAt]
      })
    end
  end
end
