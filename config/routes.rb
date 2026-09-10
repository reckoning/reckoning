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

  # A handful of paths the SPA does not name the same way it is reached by:
  # Devise's own URLs, which sit in mails already sent, and the two the user
  # menu on the server-rendered layout links. Redirected rather than served,
  # so the address bar ends up on the path the SPA knows.
  #
  # Built through this rather than through `redirect("…")`, which drops the
  # query string — and the query string is where the tokens are.
  legacy_screen = ->(pattern) do
    redirect do |params, request|
      path = pattern % params.to_h.symbolize_keys
      [path, request.query_string.presence].compact.join("?")
    end
  end

  get "/users/confirmation", to: legacy_screen.call("/confirmation")
  get "/users/confirmation/new", to: legacy_screen.call("/confirmation")
  get "/users/unlock", to: legacy_screen.call("/unlock")
  get "/users/unlock/new", to: legacy_screen.call("/unlock")
  get "/users/password/new", to: legacy_screen.call("/password/new")
  get "/users/password/edit", to: legacy_screen.call("/password/edit")

  devise_for :users,
    skip: %i[sessions registrations],
    controllers: {registrations: "registrations"}

  as :user do
    get "signup" => "accounts#new", :as => :new_registration
    post "signup" => "accounts#create", :as => :registration
    # The SPA owns the profile; saving goes through /api/v1. The path stays
    # because Devise's mails and the server-rendered screens link it.
    get "settings" => "spa#index", :as => :edit_user_registration
    # The SPA renders the login. The name stays so the handful of
    # `new_user_session_path` callers keep working, and a bookmark on /signin
    # still lands somewhere sensible.
    get "signin" => legacy_screen.call("/login"), :as => :new_user_session
    delete "signout" => "sessions#destroy", :as => :destroy_user_session
  end

  # Two-factor is the SPA's: enrolling, the backup codes and turning it off
  # all go through /api/v1. The path stays because it was linked from the
  # profile and may sit in a bookmark.
  get "me/otp", to: legacy_screen.call("/settings/two-factor"), as: :otp_me

  # The SPA owns the account settings; saving goes through /api/v1. The path
  # stays because the user menu on the server-rendered screens links it.
  get "account/edit", to: legacy_screen.call("/account"), as: :edit_account

  get "password/edit", to: legacy_screen.call("/settings/password"), as: :edit_password

  # The SPA owns the invoice list (phase B6). The name stays: the main
  # navigation links `invoices_path`, and so do the redirects after charging
  # or paying an invoice. The query travels with it, so a filtered, sorted
  # link keeps working.
  get "invoices", to: "spa#index", as: :invoices

  # The SPA owns the form too (phase B6). Declared before the resource so
  # `/invoices/new` reaches the SPA rather than the ERB screen, and named to
  # keep `new_invoice_path` — the dashboard and the project page link it.
  get "invoices/new", to: "spa#index", as: :new_invoice
  get "invoices/:id/edit", to: "spa#index", as: :edit_invoice

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
  get "invoices/:id", to: "spa#index", as: :invoice

  # The SPA owns the offer screens (phase B7). The list keeps its query — the
  # main navigation links `offers_path` — and the name comes back here now
  # that the resource no longer carries `create` to provide it.
  get "offers", to: "spa#index", as: :offers

  # `?project_id=` survives: the project page links a new offer for itself.
  get "offers/new", to: "spa#index", as: :new_offer
  get "offers/:id/edit", to: "spa#index", as: :edit_offer

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
  get "offers/:id", to: "spa#index", as: :offer

  # The SPA owns the timesheet (phase B4). The name stays: the main
  # navigation links `timesheet_path`.
  get "timesheet", to: "spa#index", as: :timesheet

  resource :template, only: [] do
    template "blank"
    template "datepicker"
    template "index_logbooks"
  end

  resources :positions, only: %i[new destroy]

  # The SPA owns the customer screens (phase B3). The name stays because the
  # project list still links here, and a bookmark on the old path should land
  # on the new screen rather than a 404.
  get "customers/:id/edit", to: "spa#index", as: :edit_customer

  # The SPA owns every project screen. The names are kept, since the
  # navigation links `projects_path` and the panels around the app link the
  # detail and the form.
  get "projects", to: "spa#index", as: :projects
  get "projects/new", to: "spa#index", as: :new_project
  get "projects/:id/edit", to: "spa#index", as: :edit_project
  get "projects/:id", to: "spa#index", as: :project

  resources :projects, only: [] do
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

  get "expenses", to: "spa#index", as: :expenses
  get "expenses/new", to: "spa#index", as: :new_expense
  get "expenses/:id/edit", to: "spa#index", as: :edit_expense

  # The import is the SPA's own screen at another path, so this one leads
  # there — it is what the list linked before the screen moved.
  get "expense_imports/new", to: legacy_screen.call("/expenses/import"), as: :new_expense_import

  get "impressum" => "base#impressum"
  get "privacy" => "base#privacy"
  get "terms" => "base#terms"

  match "404" => "errors#not_found", :via => :all
  match "422" => "errors#server_error", :via => :all
  match "500" => "errors#server_error", :via => :all

  root to: "base#index"

  # The path space the server keeps, whether or not a route above claims the
  # exact path: a typo under any of these is a 404, not a screen. `rails/` is
  # ActiveStorage's, which the framework draws after this file.
  server_owned_paths = %w[/api/ /api-docs /backend/ /cable /rails/ /up]

  # The SPA owns the rest: it is the app now, so a path nothing above claims
  # is one of its screens — or one of its screens' sub-paths, which it alone
  # knows. Declared last, so every route above wins.
  #
  # A page load is one that asks for HTML or asks for nothing in particular:
  # `*/*` is what a plain `curl` and any `fetch` without an Accept header
  # send, and answering those with a 404 would leave a route that only works
  # in a browser. Anything naming a file stays a 404, so a missing asset
  # cannot come back as a shell.
  get "*path", to: "spa#index", constraints: lambda { |request|
    format = request.format

    (format.html? || format.to_s == "*/*") &&
      File.extname(request.path).empty? &&
      server_owned_paths.none? { |prefix| request.path.start_with?(prefix) }
  }
end
