# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # Kamal/proxy healthcheck. Rails 7.1+ auto-mounts this via
  # `config.load_defaults 7.1+`; we're still on 7.0 defaults so wire it
  # manually for now.
  get "up", to: "rails/health#show", as: :rails_health_check

  draw :api_routes

  # Serves swagger/v1/schema.yaml at /api-docs/schemas/v1/schema.
  # The interactive UI stays off (`config.ui_enabled`).
  mount OpenapiRuby::Engine => "/api-docs"

  namespace :backend do
    resources :accounts, except: [:show]

    resources :users, except: [:show] do
      member do
        put "send_welcome"
      end
    end

    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => "/workers"
      mount Flipper::UI.app(Flipper) => "/flipper"
    end

    root to: "base#dashboard"
  end

  mount ActionCable.server => "/cable"

  # The SPA owns confirmation, unlock and password reset since phase B2.
  # These paths stay rather than moving into the mail templates, because a
  # link Devise sent last month is already sitting in someone's inbox and has
  # to keep working — including for a locked account, which has no other way
  # back in. The token travels in the query string, so it comes along.
  #
  # Every path below is built through this, because `redirect("/app/…")`
  # drops the query string: a bookmarked filtered list, or a link that
  # preselects a project for a new invoice, would arrive bare.
  spa_screen = ->(pattern) do
    redirect do |params, request|
      path = pattern % params.to_h.symbolize_keys
      [path, request.query_string.presence].compact.join("?")
    end
  end

  get "/users/confirmation", to: spa_screen.call("/app/confirmation")
  get "/users/confirmation/new", to: spa_screen.call("/app/confirmation")
  get "/users/unlock", to: spa_screen.call("/app/unlock")
  get "/users/unlock/new", to: spa_screen.call("/app/unlock")
  get "/users/password/new", to: spa_screen.call("/app/password/new")
  get "/users/password/edit", to: spa_screen.call("/app/password/edit")

  devise_for :users,
    skip: %i[sessions registrations],
    controllers: {registrations: "registrations"}

  as :user do
    get "signup" => "accounts#new", :as => :new_registration
    post "signup" => "accounts#create", :as => :registration
    # The SPA owns the profile; saving goes through /api/v1. The path stays
    # because Devise's mails and the server-rendered screens link it.
    get "settings" => spa_screen.call("/app/settings"), :as => :edit_user_registration
    # The SPA renders the login. The name stays so the handful of
    # `new_user_session_path` callers keep working, and a bookmark on /signin
    # still lands somewhere sensible.
    get "signin" => spa_screen.call("/app/login"), :as => :new_user_session
    delete "signout" => "sessions#destroy", :as => :destroy_user_session
  end

  # Two-factor is the SPA's: enrolling, the backup codes and turning it off
  # all go through /api/v1. The path stays because it was linked from the
  # profile and may sit in a bookmark.
  get "me/otp", to: spa_screen.call("/app/settings/two-factor"), as: :otp_me

  # The SPA owns the account settings; saving goes through /api/v1. The path
  # stays because the user menu on the server-rendered screens links it.
  get "account/edit", to: spa_screen.call("/app/account"), as: :edit_account

  get "password/edit", to: spa_screen.call("/app/settings/password"), as: :edit_password

  # The SPA owns the invoice list (phase B6). The name stays: the main
  # navigation links `invoices_path`, and so do the redirects after charging
  # or paying an invoice. The query travels with it, so a filtered, sorted
  # link keeps working.
  get "invoices", to: spa_screen.call("/app/invoices"), as: :invoices

  # The SPA owns the form too (phase B6). Declared before the resource so
  # `/invoices/new` reaches the SPA rather than the ERB screen, and named to
  # keep `new_invoice_path` — the dashboard and the project page link it.
  get "invoices/new", to: spa_screen.call("/app/invoices/new"), as: :new_invoice
  get "invoices/:id/edit", to: spa_screen.call("/app/invoices/%{id}/edit"), as: :edit_invoice

  # What is left of the server-rendered invoice: the PDFs, which the plan keeps
  # server-rendered on purpose. Charging, paying, mailing, creating, updating
  # and deleting all go through /api/v1 now, and their actions are gone.
  resources :invoices, only: [] do
    member do
      get "/pdf/:pdf" => "invoices#pdf", :as => :pdf, :defaults => {format: :pdf}
      get "/timesheet-pdf/:pdf" => "invoices#timesheet", :as => :timesheet_pdf, :defaults => {format: :pdf}
    end
  end

  # The SPA owns the detail page (phase B6). Named, now that the resource no
  # longer carries `update` and `destroy` to provide `invoice_path` — the
  # dashboard and project panels link it. Declared after the resource so its
  # `:id` cannot swallow the member routes above.
  get "invoices/:id", to: spa_screen.call("/app/invoices/%{id}"), as: :invoice

  # The SPA owns the offer screens (phase B7). The list keeps its query — the
  # main navigation links `offers_path` — and the name comes back here now
  # that the resource no longer carries `create` to provide it.
  get "offers", to: spa_screen.call("/app/offers"), as: :offers

  # `?project_id=` survives: the project page links a new offer for itself.
  get "offers/new", to: spa_screen.call("/app/offers/new"), as: :new_offer
  get "offers/:id/edit", to: spa_screen.call("/app/offers/%{id}/edit"), as: :edit_offer

  # What is left of the server-rendered offer: the PDF, which the plan keeps
  # server-rendered on purpose. Creating, updating, deleting and the state
  # machine all go through /api/v1 now, and their actions are gone.
  resources :offers, only: [] do
    member do
      get "/pdf/:pdf" => "offers#pdf", :as => :pdf, :defaults => {format: :pdf}
    end
  end

  # Named because the dashboard's offer panel links it. Declared after the
  # resource so its `:id` cannot swallow the member routes above.
  get "offers/:id", to: spa_screen.call("/app/offers/%{id}"), as: :offer

  # The SPA owns the timesheet (phase B4). The name stays: the main
  # navigation links `timesheet_path`.
  get "timesheet", to: spa_screen.call("/app/timesheet"), as: :timesheet

  resource :template, only: [] do
    template "blank"
    template "datepicker"
    template "index_logbooks"
  end

  resources :positions, only: %i[new destroy]

  # The SPA owns the customer screens (phase B3). The name stays because the
  # project list still links here, and a bookmark on the old path should land
  # on the new screen rather than a 404.
  get "customers/:id/edit", to: spa_screen.call("/app/customers/%{id}/edit"), as: :edit_customer

  # The SPA owns the project list and the form (phase B3). The detail page
  # stays here: it renders the offers and invoices panels, which belong to B6
  # and B7 — porting it now would mean building those twice. The names are
  # kept, since the main navigation links `projects_path` and the detail links
  # `edit_project_path`.
  get "projects", to: spa_screen.call("/app/projects"), as: :projects
  get "projects/new", to: spa_screen.call("/app/projects/new"), as: :new_project
  get "projects/:id/edit", to: spa_screen.call("/app/projects/%{id}/edit"), as: :edit_project

  resources :projects, only: [:show] do
    # Untouched: these serve the legacy invoice screen, not the project
    # screens this phase replaces.
    resources :tasks, only: %i[index create]
  end

  resources :timers, only: [] do
    collection do
      get :uninvoiced
    end
  end

  # The SPA owns the list, the form and the bulk actions; creating, updating
  # and deleting go through /api/v1. What is left server-rendered are the two
  # exports, which are the same path in another format — so they are declared
  # before the forward, which would otherwise swallow them.
  # Named apart from the forward below, which is what `expenses_path` means
  # to everything that links the list.
  get "expenses", to: "expenses#index", as: :expenses_export,
    constraints: ->(request) { request.format.csv? || request.format.pdf? }

  get "expenses", to: spa_screen.call("/app/expenses"), as: :expenses
  get "expenses/new", to: spa_screen.call("/app/expenses/new"), as: :new_expense
  get "expenses/:id/edit", to: spa_screen.call("/app/expenses/%{id}/edit"), as: :edit_expense
  resources :expense_imports, only: %i[new create] do
    post :preview, on: :collection
  end

  # Vue SPA shell. Scoped to /app so vue-router owns everything beneath it and
  # a reload of a client-side path still finds the shell. Deliberately not a
  # global catch-all — the ERB screens keep their routes until Phase C.
  get "app", to: "spa#index", as: :spa
  get "app/*path", to: "spa#index"

  get "impressum" => "base#impressum"
  get "privacy" => "base#privacy"
  get "terms" => "base#terms"

  match "404" => "errors#not_found", :via => :all
  match "422" => "errors#server_error", :via => :all
  match "500" => "errors#server_error", :via => :all

  root to: "base#index"
end
