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
  spa_screen = ->(path) do
    redirect { |_params, request| [path, request.query_string.presence].compact.join("?") }
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
    get "settings" => "registrations#edit", :as => :edit_user_registration
    patch "settings" => "registrations#update", :as => :update_user_registration
    # The SPA renders the login. The name stays so the handful of
    # `new_user_session_path` callers keep working, and a bookmark on /signin
    # still lands somewhere sensible.
    get "signin" => redirect("/app/login"), :as => :new_user_session
    delete "signout" => "sessions#destroy", :as => :destroy_user_session
  end

  resource :me, controller: :current_user, only: [] do
    get :otp
    get :otp_qrcode
    post :otp_backup_codes
    post :enable_otp
    post :disable_otp
  end

  resource :account, only: %i[edit update]

  resource :password, only: %i[edit update]

  resources :invoices do
    member do
      put :generate_positions
      put :charge
      put :pay
      put :send_mail
      post :send_test_mail
      get "/pdf/:pdf" => "invoices#pdf", :as => :pdf, :defaults => {format: :pdf}
      get "/timesheet-pdf/:pdf" => "invoices#timesheet", :as => :timesheet_pdf, :defaults => {format: :pdf}
    end
  end

  resources :offers do
    member do
      get "/pdf/:pdf" => "offers#pdf", :as => :pdf, :defaults => {format: :pdf}
    end
  end

  # The SPA owns the timesheet (phase B4). The name stays: the main
  # navigation links `timesheet_path`.
  get "timesheet", to: redirect { |_params, request|
    ["/app/timesheet", request.query_string.presence].compact.join("?")
  }, as: :timesheet

  resource :template, only: [] do
    template "blank"
    template "datepicker"
    template "month_timers"
    # Kept for the timers calendar, which renders this modal from
    # `angular/timers_calendar/controllers/month.coffee`. It goes with that
    # screen in phase B5, not with the timesheet.
    template "timer_modal_timesheets"
    template "index_logbooks"
  end

  resources :positions, only: %i[new destroy]

  # The SPA owns the customer screens (phase B3). The name stays because the
  # project list still links here, and a bookmark on the old path should land
  # on the new screen rather than a 404.
  get "customers/:id/edit", to: redirect("/app/customers/%{id}/edit"), as: :edit_customer

  # The SPA owns the project list and the form (phase B3). The detail page
  # stays here: it renders the offers and invoices panels, which belong to B6
  # and B7 — porting it now would mean building those twice. The names are
  # kept, since the main navigation links `projects_path` and the detail links
  # `edit_project_path`.
  get "projects", to: redirect("/app/projects"), as: :projects
  get "projects/new", to: redirect("/app/projects/new"), as: :new_project
  get "projects/:id/edit", to: redirect("/app/projects/%{id}/edit"), as: :edit_project

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

  resources :expenses, except: [:show] do
    collection do
      post :bulk_update
      post :bulk_destroy
    end
  end
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
