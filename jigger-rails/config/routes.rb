Rails.application.routes.draw do
  get "my/recipes", to: "account#recipes", as: :my_recipes
  get "my/collections", to: "collections#index", as: :my_collections
  get "my/lists", to: redirect("/my/collections"), as: :my_lists
  resources :collection_recipes, only: :create
  resources :collections do
    resources :collection_recipes, only: %i[create destroy]
  end
  get "my/profile", to: "profiles#show", as: :my_profile
  get "my/profile/edit", to: "profiles#edit", as: :edit_my_profile
  patch "my/profile", to: "profiles#update"
  get "profiles/:id", to: "profiles#show", as: :profile

  resource :registration, only: %i[ new create ]
  resource :session
  resources :passwords, param: :token
  resources :cocktails, only: %i[ index show ] do
    resource :image, only: :show, controller: "cocktail_images"
  end
  namespace :admin do
    root to: "cocktails#index"
    resources :cocktails
    resources :ingredients
    resources :utensils
    resources :recipes
  end
  resources :recipes do
    resource :star, only: %i[create destroy], controller: "recipe_stars"
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
