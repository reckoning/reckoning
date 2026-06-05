# frozen_string_literal: true

# cypress-on-rails wires Playwright (or Cypress) specs to Rails-side
# helpers. The middleware is mounted in non-production envs and
# accepts POSTs that dispatch to ruby files under
# `test/e2e/app_commands/`: DB cleaning, scenario seeding, ad-hoc
# `eval`, plus the per-failure log capture.
#
# The JS side (`test/e2e/support/on-rails.ts`) talks to it via
# `pnpm exec playwright test`.

if defined?(CypressOnRails)
  CypressOnRails.configure do |c|
    c.api_prefix = ""
    c.install_folder = Rails.root.join("test", "e2e").to_s
    c.use_middleware = !Rails.env.production?
    c.logger = Rails.logger
  end
end
