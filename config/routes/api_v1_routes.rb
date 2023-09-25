# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy]

  get "me" => "users#current"

  resources :customers, only: %i[index show create destroy]

  resources :projects, only: %i[index destroy] do
    member do
      put :archive
    end
  end

  resources :tasks, only: %i[index create]

  resources :timers, only: %i[index create update destroy] do
    member do
      put :start
      put :stop
    end
  end

  resources :users, only: [:index] do
    collection do
      get :current
    end
  end
end

scope :v1, defaults: {format: :json}, as: :v1 do
  scope module: :v1, &v1_api_routes
end
