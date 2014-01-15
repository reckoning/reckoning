require 'resque/server'

Reckoning::Application.routes.draw do
  devise_for :users, skip: [:sessions], controllers: { registrations: "registrations" }

  namespace :backend do
    resources :users, except: [:show]

    resources :settings, except: [:index, :show]

    authenticate :user, lambda {|u| u.admin? } do
      mount Resque::Server.new, :at => "/workers"
    end

    root to: 'base#dashboard'
  end

  as :user do
    get 'signup' => 'registrations#new', as: :new_registration
    get 'signin' => 'sessions#new', as: :new_user_session
    post 'signin' => 'sessions#create', as: :user_session
    delete 'signout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :bank_account, only: [:edit, :update]
  resource :password, only: [:edit, :update]

  resources :invoices, param: :ref do
    member do
      put :regenerate_pdf
      put :charge
      put :pay
      get :check_pdf
    end
  end

  get 'invoices/:ref/pdf/:pdf' => 'invoices#pdf', as: :invoice_pdf
  get 'invoices/:ref/png/:png' => 'invoices#png', as: :invoice_png

  resources :positions, only: [:new, :destroy]

  resources :customers, except: [:show]
  resources :projects, except: [:show]

  root to: 'base#index'
end
