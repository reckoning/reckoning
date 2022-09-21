# frozen_string_literal: true

endpoints = AppEndpointResolver.new

namespace :frontend, path: endpoints.frontend_base_url do
  get "dashboard" => "base#index"
  get "customers" => "base#index"

  get "projects" => "base#index"
  get 'projects/:id' => 'base#index'
  get 'projects/:id/calculator' => 'base#index'

  get "invoices" => "base#index"
  get "timers" => "base#index"
  get "timers/:year" => "base#index"
  get "expenses" => "base#index"
  get "calculator" => "base#index"
  get "calculator/:uuid" => "base#index"

  get "settings" => "base#index"
  get "settings/profile" => "base#index"
  get "settings/account" => "base#index"
  get "settings/change-password" => "base#index"
  get "settings/notifications" => "base#index"
  get "settings/security" => "base#index"
  get "settings/security/two-factor/enable" => "base#index"
  get "settings/security/two-factor/disable" => "base#index"
  get "settings/security/two-factor/backup-codes" => "base#index"

  get "sign-up" => "base#index"
  get "login" => "base#index"
  get "password/request" => "base#index"
  get "password/update/:token" => "base#password", :as => :password_reset
  get "confirm/:token" => "base#confirm", :as => :confirm

  get "impressum" => "base#index"
  get "privacy-policy" => "base#index"

  match "404" => "base#not_found", :via => :all

  root to: "base#index"
end
