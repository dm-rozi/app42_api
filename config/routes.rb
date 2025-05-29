Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root to: proc { |_env|
    [
      200,
      { "Content-Type" => "text/plain; charset=utf-8" },
      [ "Battlecruiser operational" ]
    ]
  }

  namespace :api do
    namespace :v1 do
      resources :posts, only: [ :create ] do
        resources :ratings, only: [ :create ]
        collection do
          get :top
          get :shared_ips
        end
      end
    end
  end
end
