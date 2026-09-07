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
    :self, :data, main_url, cable_url, "https://appsignal-endpoint.net", "https://fonts.googleapis.com",
    "https://fonts.gstatic.com", "https://kit.fontawesome.com", "https://pro.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://ka-p.fontawesome.com", "https://www.gstatic.com"
  ]

  # The Vite dev server is served from its own origin (skipProxy), so its assets,
  # HMR socket and injected styles need to be allowed explicitly.
  vite_hosts = []
  if Rails.env.development?
    vite_hosts = [
      ViteRuby.config.host, "localhost", "127.0.0.1",
      Rails.configuration.app.domain.split(":").first
    ].compact.uniq
  end
  vite_http = vite_hosts.map { |host| "http://#{host}:#{ViteRuby.config.port}" }
  vite_ws = vite_hosts.map { |host| "ws://#{host}:#{ViteRuby.config.port}" }

  connect_src.concat(vite_http + vite_ws)

  script_src = [
    :self, :unsafe_inline, :unsafe_eval, :blob, "https://kit.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://www.gstatic.com"
  ]
  script_src.concat(vite_http)

  worker_src = %i[self blob]

  style_src = [
    :self, :unsafe_inline, "https://fonts.googleapis.com", "https://pro.fontawesome.com",
    "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
    "https://ka-p.fontawesome.com"
  ]
  style_src.concat(vite_http)

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

  # You may need to enable this in production as well depending on your setup.
  #    policy.script_src *policy.script_src, :blob if Rails.env.test?

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
end
