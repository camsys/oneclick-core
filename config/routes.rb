Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    match '*path', :controller => 'api', :action => 'handle_options_request', via: [:options]

    namespace :v1 do

      resources :users do
        collection do
          get 'profile'
          get 'get_guest_token'
          post 'update'
        end
      end

      devise_scope :user do
        post 'sign_up' => 'registrations#create'
        post 'sign_in' => 'sessions#create'
        delete 'sign_out' => 'sessions#destroy'
      end

      resources :places do
        collection do
          get 'search'
          get 'recent'
          get 'search'
          post 'within_area'
        end
      end #places

      resources :translations do
        collection do
          post 'find'
          get  'all'
        end
      end

      resources :trips, only: [:create]

      post 'itineraries/plan' => 'trips#create'

    end #v1

    namespace :v2 do
      devise_scope :user do
        post 'sign_up' => 'registrations#create'
      end
    end #v2

  end #api

  #Admin Views
  namespace :admin do
    resources :users, :only => [:index]

    resources :configs, :only => [:index] do
      collection do
        patch 'set_open_trip_planner'
      end
    end

    resources :landmarks, :only => [:index] do
      collection do
        patch 'update_all'
      end
    end

    resources :eligibilities, :only => [:index, :destroy, :create]
    resources :accommodations, :only => [:index, :destroy, :create]
    resources :purposes, :only => [:index, :destroy, :create]
    resources :services, :only => [:index, :destroy, :create, :show, :update]

    get 'geographies' => 'geographies#index'
    post 'counties' => 'geographies#upload_counties'
    post 'cities' => 'geographies#upload_cities'
    post 'zipcodes' => 'geographies#upload_zipcodes'
    post 'custom_geographies' => 'geographies#upload_custom_geographies'

  end #Admin

  mount SimpleTranslationEngine::Engine => "/admin/simple_translation_engine"


end #draw
