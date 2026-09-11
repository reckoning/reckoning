# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # Only `destroy` is left here, and it redirects — the SPA renders the form.
end
