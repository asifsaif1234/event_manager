Rails.application.routes.draw do
  get "/sign_in", to: redirect("https://guiding-grouper-6633.accounts.dev/sign-in")
  get "/sign_up", to: redirect("https://guiding-grouper-6633.accounts.dev/sign-up")
  # config/routes.rb
  # delete '/sign_out', to: 'sessions#destroy'
  match "/sign_out", to: "sessions#destroy", via: [ :get, :delete ]
  get "/auth/callback", to: "sessions#create"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "events#index"

  resources :events, only: [ :index ] do
    collection do
      post :ingest
      post :ingest_all
      get :sync_status
    end
  end
end
