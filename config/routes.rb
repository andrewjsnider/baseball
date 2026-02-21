Rails.application.routes.draw do
  root to: 'dashboard#index'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  resources :games do
    resource :lineup do
      patch :reorder
      patch :assign_positions
      patch :update_pitch_limit
    end
  end

  resources :lineups, only: [:show] do
    member do
      patch :update_order
    end
  end

  get 'players/import', to: 'players#import_form', as: :import_players_show

  resources :players do

    member do
      post :draft
      post :undraft
      get :assign
      patch :assign_to_team
    end

    collection do
      post :import
    end
  end

  resources :teams
  # Defines the root path route ("/")
  # root "posts#index"
end
