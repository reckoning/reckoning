require 'sidekiq/web'

Reckoning::Application.routes.draw do
  v1_api_routes = lambda do
    post 'signin' => 'session#create'
    resource :account do
      get :verify_iban
      get :generate_iban
    end

    resources :customers, only: [:index, :show, :create, :destroy]

    resources :projects, only: [:index, :destroy] do
      member do
        put :archive
      end
    end

    resources :tasks, only: [:index, :create]

    resources :timers, only: [:index, :create, :update, :destroy] do
      member do
        put :start
        put :stop
      end
    end
  end

  v1_backend_api_routes = lambda do
    resources :accounts
  end

  scope module: :api, constraints: { subdomain: "api" } do
    scope :v1, defaults: { format: :json }, as: :v1 do
      scope module: :v1, &v1_api_routes
    end
  end

  namespace :backend do
    scope module: "api", constraints: { subdomain: "api" } do
      scope :v1, defaults: { format: :json }, as: :v1 do
        scope module: :v1, &v1_backend_api_routes
      end
    end

    resources :accounts, except: [:show]

    resources :users, except: [:show] do
      member do
        put 'send_welcome'
      end
    end

    resources :contacts, only: [:index]

    authenticate :user, ->(u) { u.admin? } do
      mount Sidekiq::Web => '/workers'
    end

    root to: 'base#dashboard'
  end

  devise_for :users,
             skip: [:sessions, :registrations],
             controllers: { registrations: "registrations" }

  as :user do
    get 'signup' => 'accounts#new', as: :new_registration
    post 'signup' => 'accounts#create', as: :registration
    get 'settings' => 'registrations#edit', as: :edit_user_registration
    patch 'settings' => 'registrations#update', as: :update_user_registration
    get 'signin' => 'sessions#new', as: :new_user_session
    post 'signin' => 'sessions#create', as: :user_session
    delete 'signout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :me, controller: :current_user, only: [] do
    get :otp
    get :otp_qrcode
    post :otp_backup_codes
    post :enable_otp
    post :disable_otp
  end

  resource :account, only: [:edit, :update]

  resource :password, only: [:edit, :update]

  resources :invoices do
    collection do
      put "archive" => "invoices#archive_all"
    end
    member do
      put :generate_positions
      put :charge
      put :pay
      put :archive
      put :send_mail
      post :send_test_mail
      get "/pdf/:pdf" => 'invoices#pdf', as: :pdf, defaults: { format: :pdf }
      get '/timesheet-pdf/:pdf' => 'invoices#timesheet', as: :timesheet_pdf, defaults: { format: :pdf }
    end
  end

  resource :timesheet, only: [:show] do
    member do
      get :day_template
      get :week_template
      get :timer_modal_template
      get :task_modal_template
    end
    # get :new_import
    # post :csv_import
  end

  resource :template, only: [] do
    get "blank" => "templates#show"
    get "datepicker" => "templates#show"
    get "month_timers" => "templates#show"
  end

  resources :positions, only: [:new, :destroy]

  resources :customers, only: [:edit, :update]
  resources :projects, except: [:destroy] do
    member do
      put :unarchive
    end

    resources :tasks, only: [:index, :create] do
      collection do
        get :uninvoiced
      end
    end
  end

  resources :expenses, except: [:show]

  resource :dropbox, controller: "dropbox", only: [:show] do
    collection do
      get :start
      get :activate
      get :deactivate
    end
  end

  resources :contacts, only: [:create]

  get 'impressum' => 'base#impressum'
  get 'privacy' => 'base#privacy'
  get 'terms' => 'base#terms'

  get '404' => 'errors#not_found'
  get '422' => 'errors#server_error'
  get '500' => 'errors#server_error'

  mount Peek::Railtie => '/peek'

  root to: 'base#index'
end
