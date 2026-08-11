Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Email/password authentication (SPEC M2). Custom controllers add the
  # Turnstile check and the legal-assent record on top of stock Devise.
  devise_for :users, controllers: {
    registrations: "users/registrations",
    passwords: "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Operator administration (SPEC M6). The authenticated route constraint
  # prevents the admin surface from matching for guests, normal users, or
  # organization admins. Controllers repeat the User#admin? authorization so
  # mounted engines and future route changes still fail closed independently.
  authenticated :user, ->(user) { user.admin? } do
    scope path: "admin", module: "madmin", as: "madmin" do
      get "dashboard", to: "dashboard#show", as: :root

      resources :users, only: %i[index show] do
        post :lock, on: :member
        post :unlock, on: :member
        post :revoke_all_sessions, on: :member
      end
      resources :organizations, only: %i[index show] do
        post :assign_plan, on: :member
        post :remove_plan, on: :member
      end
      resources :memberships, only: %i[index show]
      resources :invitations, only: %i[index show]
      resources :sessions, only: %i[index show] do
        post :revoke, on: :member
      end
      resources :events, only: %i[index show], path: "login-activity", controller: "session_events"
    end

    mount MissionControl::Jobs::Engine => "/admin/jobs", as: :admin_jobs
  end

  # Versioned legal documents (SPEC M2.4).
  get "legal/terms",   to: "foundation/legal#terms",   as: :legal_terms
  get "legal/privacy", to: "foundation/legal#privacy", as: :legal_privacy

  # Public tier comparison plus organization-scoped Stripe Checkout and
  # customer portal flows (SPEC M5). Pay mounts signed webhook endpoints at
  # /pay/webhooks/:provider separately.
  get  "pricing",          to: "foundation/pricing#show",  as: :pricing
  get  "billing",          to: "foundation/billing#show",  as: :billing
  post "billing/checkout", to: "foundation/billing#checkout", as: :billing_checkout
  post "billing/portal",   to: "foundation/billing#portal",   as: :billing_portal

  # Legal-assent interstitial for first-time OAuth users (SPEC M3.3):
  # shown before any account is created; DELETE declines and abandons it.
  get    "oauth/assent", to: "foundation/oauth_signups#new", as: :oauth_assent
  post   "oauth/assent", to: "foundation/oauth_signups#create"
  delete "oauth/assent", to: "foundation/oauth_signups#destroy"

  # Linked sign-in providers: explicit connect/disconnect (SPEC M3.3).
  get    "settings/connections",     to: "foundation/connections#show",    as: :settings_connections
  delete "settings/connections/:id", to: "foundation/connections#destroy", as: :settings_connection

  # Organization invitation emails carry a signed, expiring token
  # (SPEC M4.2); redeeming it lands on the public acceptance page. Declared
  # before the engine mount so it wins over the engine's GET
  # /invitations/:token.
  get "invitations/mail/:signed_token",
    to: "foundation/invitation_links#show", as: :organization_invitation_link

  # Team workspaces: organizations, members, switching, and invitations
  # (SPEC M4) — the organizations gem's engine, mounted at the root.
  mount Organizations::Engine => "/"

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
