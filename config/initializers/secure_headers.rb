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
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  config.referrer_policy = 'no-referrer'
  config.clear_site_data = %w[
    cache
    cookies
    storage
    executionContexts
  ]

  # rubocop:disable Lint/PercentStringArray
  config.csp = {
    preserve_schemes: true,

    default_src: %w[https: 'self'],
    base_uri: %w['self'],
    block_all_mixed_content: true,
    child_src: %w['self'],
    connect_src: %w[wss:],
    font_src: %w['self' data:],
    frame_ancestors: %w['none'],
    object_src: %w['self'],
    script_src: %w['self' 'unsafe-inline'],
    style_src: %w['self' 'unsafe-inline' fonts.googleapis.com],
    upgrade_insecure_requests: true,
    report_uri: %w[https://mortik.report-uri.io/r/default/csp/enforce]
  }

  config.hpkp = {
    report_only: false,
    max_age: 60.days.to_i,
    include_subdomains: true,
    report_uri: "https://mortik.report-uri.io/r/default/hpkp/enforce",
    pins: [
      { sha256: "QDswWuU7+p+bL6X8qrjr9lj3qpkz8veaoqsaDa3Ys+I=" },
      { sha256: "YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=" },
      { sha256: "Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys=" }
    ]
  }
end
