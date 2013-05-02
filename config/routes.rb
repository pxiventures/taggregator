require 'sidekiq/web'

Taggregator::Application.routes.draw do
  mount RailsAdmin::Engine => '/railsadmin', :as => 'rails_admin'

  admin_constraint = lambda do |request|
    request.session[:user_id] && User.find(request.session[:user_id]).admin?
  end
  constraints admin_constraint do
    mount Sidekiq::Web, :at => "/sidekiq"
  end

  namespace :admin do
    root to: "root#index"
    post '/daily_email_test' => "root#daily_email_test", :as => "daily_email_test"
    post '/daily_email' => "root#daily_email", :as => "daily_email"
    post '/force_update' => "root#force_update", :as => "force_update"
    resources :subscriptions, :only => [:index, :destroy, :create]
    resources :campaigns do
      member do
        post :set_winning_photo
      end
      collection do
        post :quick_add
      end

      resources :campaign_photos, only: [:index, :update], as: :photos
    end
    resources :tags, only: [:index, :new, :create]
  end    
  match "/auth/instagram/callback" => "sessions#create"
  get "/logout" => "sessions#destroy", :as => "logout"
  get "/email" => "sessions#email", :as => "email"
  post "/email" => "sessions#update_email", :as => "email"
  get "verify" => "sessions#verify", :as => "verify_email"

  get "/instagram/callback" => "realtime#instagram_challenge", :as => :instagram_callback
  post "/instagram/callback" => "realtime#instagram_callback", :as => :instagram_callback
  
  get "/facebook/callback" => "photos#fb_feed_post_callback", :as => :facebook_callback

  resources :tags, only: [:index]

  resources :campaigns, only: [:index, :show] do
    member do
      get :leaderboard
      get :embed
    end
    collection do
      get :top_photos
    end
  end

  resources :photos, only: [:index, :show] do
    collection do
      get :participating_in
    end
    member do
      post :add_to_campaign
    end
  end

  resource :user, only: [] do
    get :profile
    put :update_profile
    get :leaderboard
    match :like
    post :follow
    post :comment
    get :verify
  end
  
  root to: "campaigns#index"
end
