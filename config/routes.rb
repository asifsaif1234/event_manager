Rails.application.routes.draw do
  mount RailsEventStore::Browser => "/res" if Rails.env.development?

  get "/sign_in", to: redirect("https://guiding-grouper-6633.accounts.dev/sign-in")
  get "/sign_up", to: redirect("https://guiding-grouper-6633.accounts.dev/sign-up")
  match "/sign_out", to: "sessions#destroy", via: [ :get, :delete ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  # Ignore Chrome DevTools requests
  get "/.well-known/*path", to: proc { [ 204, {}, [ "" ] ] }

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
    member do
      post :vote
    end
  end
  # For test caese
  resource :session, only: [ :create, :destroy ]
end
