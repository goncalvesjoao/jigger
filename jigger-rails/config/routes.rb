Rails.application.routes.draw do
  resource :registration, only: %i[ new create ]
  resource :session
  resources :passwords, param: :token
  resources :cocktails, only: %i[ index show ]
  namespace :admin do
    resources :cocktails, only: %i[ new create edit update destroy ]
  end
  resources :recipes do
    resource :image, only: :show, controller: "recipe_images"
  end
  resources :ingredients, only: [] do
    resource :image, only: :show, controller: "ingredient_images"
  end
  resources :utensils, only: [] do
    resource :image, only: :show, controller: "utensil_images"
  end
  scope ActiveStorage.routes_prefix do
    get "/disk/:encoded_key/*filename", to: "active_storage/disk#show", as: :rails_disk_service
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "cocktails#index"
end
