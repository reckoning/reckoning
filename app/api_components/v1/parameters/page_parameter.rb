# frozen_string_literal: true

module V1
  module Parameters
    class PageParameter
      include OpenapiRuby::Components::Base

      component_type :parameters

      schema({
        name: :page,
        in: :query,
        required: false,
        description: "1-based page number. Page boundaries are described by the Link response header.",
        schema: {type: :integer, minimum: 1}
      })
    end
  end
end
