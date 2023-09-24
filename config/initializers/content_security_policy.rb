# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

require "uri"

Rails.application.config.content_security_policy do |policy|
  main_url = "http://#{Rails.configuration.app.domain}"
  cable_url = "ws://#{Rails.configuration.app.domain}"
  if Rails.configuration.force_ssl
    main_url = "https://#{Rails.configuration.app.domain}"
    cable_url = "wss://#{Rails.configuration.app.domain}"
  end

  connect_src = [
    :self, :data, main_url, cable_url, "https://sentry.io", "https://fonts.googleapis.com",
    "https://fonts.gstatic.com", "https://kit.fontawesome.com", "https://pro.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://ka-p.fontawesome.com", "https://www.gstatic.com"
  ]

  if Rails.env.development?
    connect_src.concat [
      "ws://localhost:3035", "http://localhost:3035",
      "ws://reckoning.test:3035", "http://reckoning.test:3035", "ws://reckoning.test:3036"
      # "ws://#{ViteRuby.config.host_with_port}"
    ]
  end

  script_src = [
    :self, :unsafe_inline, :unsafe_eval, :blob, "https://kit.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://www.gstatic.com"
  ]
  # script_src << "http://#{ViteRuby.config.host_with_port}" if Rails.env.development?

  worker_src = %i[self blob]

  style_src = [
    :self, :unsafe_inline, "https://fonts.googleapis.com", "https://pro.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://ka-p.fontawesome.com"
  ]

  img_src = [
    :self, :data, :blob, Rails.application.credentials.carrierwave_cloud_cdn_endpoint,
    "https://img.buymeacoffee.com", "https://www.gravatar.com"
  ].compact

  font_src = [
    :self, "https://fonts.gstatic.com", "https://pro.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://ka-p.fontawesome.com"
  ]

  frame_src = %i[self blob]

  policy.default_src :none
  policy.base_uri :self
  policy.manifest_src :self
  policy.form_action :self
  policy.connect_src(*connect_src)
  policy.script_src(*script_src)
  policy.style_src(*style_src)
  policy.img_src(*img_src)
  policy.font_src(*font_src)
  policy.frame_src(*frame_src)
  policy.child_src(*worker_src)
  policy.worker_src(*worker_src)
  policy.prefetch_src(*img_src)
  policy.object_src :self
  policy.frame_ancestors :none

  policy.upgrade_insecure_requests true unless Rails.env.development? || Rails.env.test?

  # policy.report_uri Rails.application.credentials.sentry_csp_uri if Rails.application.credentials.sentry_csp_uri.present?
end
