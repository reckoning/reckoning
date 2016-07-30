# encoding: utf-8
# frozen_string_literal: true
require 'sidekiq/web'

Rails.application.routes.draw do
  draw :api_routes

  namespace :backend do
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

  mount ActionCable.server => '/cable'

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

  resource :timesheet, only: [:show]

  resource :template, only: [] do
    get "blank" => "templates#show"
    get "datepicker" => "templates#show"
    get "month_timers" => "templates#show"
    get "day_timesheets" => "templates#show"
    get "week_timesheets" => "templates#show"
    get "timer_modal_timesheets" => "templates#show"
    get "task_modal_timesheets" => "templates#show"
  end

  resources :positions, only: [:new, :destroy]

  resources :customers, only: [:edit, :update]
  resources :projects, except: [:destroy] do
    member do
      put :unarchive
    end

    resources :tasks, only: [:index, :create]
  end

  resources :timers, only: [] do
    collection do
      get :uninvoiced
    end
  end

  resources :expenses, except: [:show]
  resources :expense_imports, only: [:new, :create]

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

  root to: 'base#index'
end
