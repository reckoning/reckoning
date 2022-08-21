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

    authenticate :user, (->(u) { u.admin? }) do
      mount Sidekiq::Web => '/workers'
    end

    root to: 'base#dashboard'
  end

  mount ActionCable.server => '/cable'

  devise_for :users,
             skip: %i[sessions registrations],
             controllers: { registrations: 'registrations' }

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

  resource :account, only: %i[edit update]

  resource :password, only: %i[edit update]

  resources :invoices do
    collection do
      put 'archive' => 'invoices#archive_all'
    end
    member do
      put :generate_positions
      put :charge
      put :pay
      put :archive
      put :send_mail
      post :send_test_mail
      get '/pdf/:pdf' => 'invoices#pdf', as: :pdf, defaults: { format: :pdf }
      get '/timesheet-pdf/:pdf' => 'invoices#timesheet', as: :timesheet_pdf, defaults: { format: :pdf }
    end
  end

  resource :timesheet, only: [:show]

  resource :template, only: [] do
    template 'blank'
    template 'datepicker'
    template 'month_timers'
    template 'day_timesheets'
    template 'week_timesheets'
    template 'timer_modal_timesheets'
    template 'task_modal_timesheets'
    template 'index_logbooks'
    template 'vessel_logbooks'
    template 'vessel_modal_logbooks'
    template 'tour_logbooks'
    template 'tour_modal_logbooks'
    template 'waypoint_modal_logbooks'
    template 'map_modal_logbooks'
  end

  resources :positions, only: %i[new destroy]

  resources :customers, only: %i[edit update]
  resources :projects, except: [:destroy] do
    member do
      put :unarchive
    end

    resources :tasks, only: %i[index create]
  end

  resources :timers, only: [] do
    collection do
      get :uninvoiced
    end
  end

  resources :expenses, except: [:show]
  resources :expense_imports, only: %i[new create]

  resource :logbook, only: [:show]

  resource :dropbox, controller: 'dropbox', only: [:show] do
    collection do
      get :start
      get :activate
      get :deactivate
    end
  end

  get 'impressum' => 'base#impressum'
  get 'privacy' => 'base#privacy'
  get 'terms' => 'base#terms'

  match '404' => 'errors#not_found', via: :all
  match '422' => 'errors#server_error', via: :all
  match '500' => 'errors#server_error', via: :all

  root to: 'base#index'
end
