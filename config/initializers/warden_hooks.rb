# encoding: utf-8
# frozen_string_literal: true
Warden::Manager.after_set_user do |user, auth, opts|
  scope = opts[:scope]
  auth.cookies.signed["#{scope}.uuid"] = user.id
  auth.cookies.signed["#{scope}.expires_at"] = 30.minutes.from_now
end
