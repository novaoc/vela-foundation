Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Email/password authentication (SPEC M2). Custom controllers add the
  # Turnstile check and the legal-assent record on top of stock Devise.
  devise_for :users, controllers: {
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  # Versioned legal documents (SPEC M2.4).
  get "legal/terms",   to: "foundation/legal#terms",   as: :legal_terms
  get "legal/privacy", to: "foundation/legal#privacy", as: :legal_privacy

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Deeper operational healthcheck (database, migrations, queue, storage);
  # checks are defined in config/allgood.rb.
  mount Allgood::Engine => "/healthcheck"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Minimal landing page until the M7 marketing set replaces it.
  root "foundation/home#show"
end
