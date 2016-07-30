# encoding: utf-8
# frozen_string_literal: true
v1_api_routes = lambda do
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

scope :v1, defaults: { format: :json }, as: :v1 do
  scope module: :v1, &v1_api_routes
end
