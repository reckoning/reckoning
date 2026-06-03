# frozen_string_literal: true

# Sessions live in Rails.cache (Redis in dev/prod, null in test).
# Cache-store namespacing keeps session keys isolated from fragment cache.
Reckoning::Application.config.session_store :cache_store,
  key: Rails.configuration.cookie_prefix,
  domain: Rails.configuration.app.cookie_domain,
  secure: Rails.env.production?,
  expire_after: 2.hours,
  same_site: :lax
