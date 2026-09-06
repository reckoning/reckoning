# frozen_string_literal: true

class JSONFailureApp < Devise::FailureApp
  def respond
    if request.format == :json
      json_failure
    else
      super
    end
  end

  def json_failure
    self.status = 401
    self.content_type = "application/json"
    self.response_body = {code: "unauthorized", message: i18n_message}.to_json
  end

  # The SPA owns the login, so a server-rendered screen that turns a visitor
  # away has to hand over where they were going. `return` rather than
  # `redirect`, because these paths live outside the SPA and getting back to
  # them needs a full page load — the two cannot be told apart from the path
  # alone now that both worlds answer to `/customers`.
  def redirect_url
    return super unless resumable_attempt?

    "#{SPA_LOGIN_PATH}?return=#{CGI.escape(attempted_path)}"
  end

  # Only a GET can be handed back. The SPA finishes the login with a page
  # load, which is a GET whatever the request that failed was — so carrying
  # `PATCH /customers/1` or `DELETE /invoices/1` would replay it as a GET
  # against a route that only answers to the original verb. Devise's own
  # `store_location!` draws the line in the same place.
  private def resumable_attempt?
    attempted_path.present? && request.get? && !request.xhr?
  end

  # Devise flashes "you need to sign in" for the login screen to render. The
  # SPA never sees it, so it would sit in the session and surface on the next
  # server-rendered page — which the visitor reaches *after* signing in.
  def redirect
    super
    flash.discard(:alert)
  end

  SPA_LOGIN_PATH = "/app/login"
end
