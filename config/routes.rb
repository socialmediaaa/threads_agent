Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"

  resources :thread_accounts, only: [ :index, :new, :create, :destroy ]
  resources :posts, only: [ :index, :new, :create, :show ] do
    member do
      patch :approve
    end
  end
end
