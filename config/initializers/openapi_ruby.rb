# frozen_string_literal: true

OpenapiRuby.configure do |config|
  config.schemas = {
    "v1/schema" => {
      openapi_version: "3.1.0",
      info: {
        title: "Reckoning API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/mortik/reckoning/blob/main/LICENSE"
        }
      },
      # The first server's path is also what the test DSL prepends to every
      # `api_path`, so paths are declared relative to it (`/customers`, not
      # `/api/v1/customers`).
      servers: [
        {url: "/api/v1", description: "Current host"}
      ],
      security: [
        {SessionCookie: []},
        {BearerAuth: []}
      ],
      prefix: "/api/v1"
    }
  }

  config.component_paths = ["app/api_components"]

  # Components spell out camelCase literally, matching what jbuilder emits
  # (`Jbuilder.key_format camelize: :lower`). Grepping a property name in the
  # schema finds it in the view.
  config.camelize_keys = false

  config.schema_output_format = :yaml
  config.schema_output_dir = "swagger"

  # Undocumented paths pass straight through (strict_mode is off), but a
  # *partially* described one would start rejecting traffic the legacy
  # AngularJS frontend still sends. Warn until the SPA is the only client,
  # then flip to :enabled (see Phase C in docs/vue-spa-migration-plan.md).
  config.request_validation = :warn_only
  config.response_validation = :disabled
  config.strict_reference_validation = :warn_only

  config.ui_enabled = false
end
