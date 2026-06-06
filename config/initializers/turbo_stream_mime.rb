# frozen_string_literal: true

# Register the Turbo Stream MIME so Rails resolves
# `request.format` to the `:turbo_stream` symbol on form submissions
# that Turbo Drive sends with `Accept: text/vnd.turbo-stream.html`.
#
# We use `@hotwired/turbo` via Vite rather than the `turbo-rails`
# gem (the gem would also pull a Sprockets-loaded JS that fights
# our Vite-loaded one), so the MIME isn't registered for us — do
# it manually.
#
# Why this matters: `Devise::FailureApp#request_format` falls back
# to `request.format.try(:ref)`, which returns the MIME's symbol
# when registered and the literal MIME string when not. With this
# MIME unregistered, `request_format` ends up as the string
# "text/vnd.turbo-stream.html", which doesn't match
# `Devise.navigational_formats = ["*/*", :html, :turbo_stream]`.
# `is_navigational_format?` then returns false, `http_auth?` returns
# true, and Devise answers a failed sign-in with a 401 instead of
# recalling the controller with `flash.now[:alert]` — so the noty
# error toast never shows.
Mime::Type.register "text/vnd.turbo-stream.html", :turbo_stream unless Mime::Type.lookup_by_extension(:turbo_stream)
