require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users,
             controllers: {omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations",
                           sessions: "users/sessions"}

  ### Registered users
  authenticated :user do
    root to: "customer/dashboard#index", as: :authenticated_root
  end
  
  scope :users, module: "users" do
    resource :profiles, only: %i[edit update], as: :profile
    delete "identities", to: "identities#destroy"
  end

  ### Admins
  namespace :admin do
    get "/", to: "dashboard#index", as: :dashboard

    resources :users do
      # roles
      delete "/roles/:role_name", to: "roles#destroy", as: :role
      post "/roles/", to: "roles#create", as: :add_role

      # bans
      post "/ban", to: "bans#create", as: :create_ban
      delete "/ban", to: "bans#destroy", as: :remove_ban

      # pretending
      post :impersonate, on: :member
      post :stop_impersonating, on: :collection

      resources :login_activities, only: [:index, :show], shallow: true
    end
  end

  authenticate :user, ->(u) { u.is_admin? } do
    mount Sidekiq::Web, at: "/sidekiq"
    mount Blazer::Engine, at: "/blazer"
  end

  ### All visitors
  get "/terms", to: "pages#terms"
  get "/privacy", to: "pages#privacy"

  root to: "pages#home"

  ### Errors
  match "/404", to: "errors#not_found", via: :all
  match "/406", to: "errors#unacceptable", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  ### Developer tools
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end