require 'sidekiq/web'

Reckoning::Application.routes.draw do
  devise_for :users,
    skip: [:sessions, :registrations],
    controllers: { registrations: "registrations" }

  namespace :backend do
    resources :users, except: [:show] do
      member do
        put 'send_welcome'
      end
    end

    resources :settings, except: [:index, :show]

    authenticate :user, lambda {|u| u.admin? } do
      mount Sidekiq::Web => '/workers'
    end

    root to: 'base#dashboard'
  end

  namespace :api do
    resources :tasks
    resources :timers
  end

  as :user do
    get 'signup' => 'registrations#new', as: :new_user_registration
    post 'signup' => 'registrations#create', as: :user_registration
    get 'settings' => 'registrations#edit', as: :edit_user_registration
    patch 'settings' => 'registrations#update', as: :update_user_registration
    get 'signin' => 'sessions#new', as: :new_user_session
    post 'signin' => 'sessions#create', as: :user_session
    delete 'signout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :password, only: [:edit, :update]

  resources :invoices do
    collection do
      put "archive" => "invoices#archive_all"
    end
    member do
      put :generate_positions
      put :regenerate_pdf
      put :charge
      put :pay
      get :check_pdf
      put :archive
      put :send_mail
      post :send_test_mail
    end
  end

  get 'invoices/:id/pdf/:pdf' => 'invoices#pdf', as: :invoice_pdf
  get 'timesheets/:id/pdf/:pdf' => 'invoices#timesheet', as: :timesheet_pdf

  resources :positions, only: [:new, :destroy]

  resources :customers, except: [:show]
  resources :projects do
    resources :tasks, only: [:index, :create] do
      collection do
        get 'uninvoiced'
      end
    end
  end

  resources :timers, only: [:index] do
    collection do
      get :day
      get :new_import
      post :csv_import
    end
  end

  resources :weeks, only: [:create, :update] do
    collection do
      post :add_task
    end
    member do
      put 'remove_task/:task_id' => 'weeks#remove_task', as: :remove_task
    end
  end

  resource :dropbox, controller: "dropbox", only: [] do
    collection do
      get :start
      get :activate
      get :deactivate
    end
  end

  get '404' => 'errors#not_found'
  get '422' => 'errors#server_error'
  get '500' => 'errors#server_error'

  root to: 'base#index'
end
