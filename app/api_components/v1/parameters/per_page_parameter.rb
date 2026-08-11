# frozen_string_literal: true

module V1
  module Parameters
    class PerPageParameter
      include OpenapiRuby::Components::Base

      component_type :parameters

      schema({
        name: :perPage,
        in: :query,
        required: false,
        description: "Page size, or \"all\" to skip pagination entirely. " \
                     "Values above the endpoint's maximum are rejected with 400.",
        schema: {
          oneOf: [
            {type: :integer, minimum: 1},
            {type: :string, enum: ["all"]}
          ]
        }
      })
    end
  end
end
