# encoding: utf-8
# frozen_string_literal: true

SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      lax: true # mark all cookies as SameSite=lax
    }
  }
  # Add "; preload" and submit the site to hstspreload.org for best protection.
  config.hsts = nil
  config.x_frame_options = nil
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "strict-origin-when-cross-origin"
  config.clear_site_data = %w[
    cache
    cookies
    storage
    executionContexts
  ]

  config.csp = {
    preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.

    default_src: %w[https: self],
    base_uri: %w[self],
    block_all_mixed_content: true,
    child_src: %w[self],
    connect_src: %w[wss:],
    font_src: %w[self data:],
    frame_ancestors: %w[none],
    object_src: %w[self],
    script_src: %w[self],
    style_src: %w[unsafe-inline],
    upgrade_insecure_requests: true,
    report_uri: %w[https://053645df64da2ba3e3f2b3b53e6e95b0.report-uri.io/r/default/csp/enforce]
  }
end
