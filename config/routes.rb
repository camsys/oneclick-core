Rails.application.routes.draw do
  
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  ### JSON API ###
  namespace :api do

    ### API V1 (LEGACY) ###
    namespace :v1 do
      
      # Places
      resources :places do
        collection do
          get 'search'
          get 'recent'
          get 'search'
          post 'within_area'
        end
      end #places
      
      # Translations
      resources :translations do
        collection do
          post 'find'
          get  'all'
        end
      end
      
      # Trips & Itineraries/Planning
      resources :trips, only: [:create] do 
        collection do
          post 'email'
        end
      end
      get 'trips/past_trips' => 'trips#past_trips'
      get 'trips/future_trips' => 'trips#future_trips'
      # post 'trips/past_trips' => 'trips#index'
      post 'itineraries/plan' => 'trips#create'
      post 'itineraries/select' => 'trips#select'
      post 'itineraries/cancel' => 'trips#cancel'
      post 'itineraries/book' => 'trips#book'
      
      # Users
      resources :users do
        collection do
          get 'profile'
          get 'get_guest_token'
          post 'update'
          post 'password'
          post 'request_reset'
          post 'reset'
        end
      end
      
      devise_scope :user do
        post 'sign_up' => 'registrations#create'
        post 'sign_in' => 'sessions#create'
        post 'sign_out' => 'sessions#destroy'
        delete 'sign_out' => 'sessions#destroy'
      end #users

    end #v1


    ### API V2 ###
    namespace :v2 do
      
      # Agencies
      resources :agencies, only: [:index]
      
      # Alerts
      resources :alerts, only: [:index, :update]
      
      # Feedbacks
      resources :feedbacks, only: [:create]
      
      # Places, Stomping Grounds, Landmarks
      resources :places, only: [:index]
      resources :stomping_grounds, only: [:index, :destroy, :create, :update]

      # Services
      resources :services, only: [:index]

      # Trips
      resources :trips, only: [:create]
      post 'trips/plan' => 'trips#create'
      post 'trips/plan_multiday' => 'trips#plan_multiday'
      
      # Users
      resource :users, only: [:show, :update, :create] do
        collection do
          post 'reset_password'
        end
      end
      post 'sign_up' => 'users#create'
      post 'sign_in' => 'users#new_session'
      delete 'sign_out' => 'users#end_session'

      # Refernet
      if ENV["ONECLICK_REFERNET"]
        get 'oneclick_refernet/services' => 'refernet/services#index'
        mount OneclickRefernet::Engine => "/oneclick_refernet"
      end
      
    end #v2


    ### MISC REQUEST HANDLING ###
    
    match '*path', :controller => 'api', :action => 'handle_options_request', via: [:options]
    # match '*path', via: [:options], to: lambda {|_| [204, {'Content-Type' => 'text/plain'}, []]}
    
    # Any unknown route should get a 404 response back
    # match '*a', via: [:get], to: lambda {|_| [404, {"Content-Type" => "application/json; charset=utf-8"}, ['']]}
    match '*a', via: :all, controller: 'api', action: 'no_route'

  end #api
  

  ### ADMIN INTERFACE ###
  root "admin/admin#index"
  
  namespace :admin do

    get '/' => 'admin#index'

    # Accommodations
    resources :accommodations, :only => [:index, :destroy, :create, :edit, :update]
    
    # Agencies
    resources :agencies, only: [:index, :destroy, :create, :show, :update]

    # Configs
    resources :configs, only: [:index]
    patch 'configs' => 'configs#update'

    # Eligibilities
    resources :eligibilities, :only => [:index, :destroy, :create, :edit, :update]

    # Feedbacks
    resources :feedbacks, :only => [:index, :show, :update] do
      collection do
        get 'acknowledged'
      end
    end

    # Alerts
    resources :alerts, :only => [:index, :destroy, :create, :edit, :update] do
      collection do
        get 'expired'
      end
    end

    # Geographies
    get 'geographies' => 'geographies#index'
    post 'counties' => 'geographies#upload_counties'
    post 'cities' => 'geographies#upload_cities'
    post 'zipcodes' => 'geographies#upload_zipcodes'
    post 'custom_geographies' => 'geographies#upload_custom_geographies'
    get 'autocomplete' => 'geographies#autocomplete'

    # Landmarks
    resources :landmarks, :only => [:index] do
      collection do
        patch 'update_all'
      end
    end

    # Purposes
    resources :purposes, :only => [:index, :destroy, :create, :edit, :update]

    # Reports
    resources :reports, only: [:index] do
      collection do
        post 'dashboard'
        get 'planned_trips_dashboard'
        post 'download_table'        
        get 'users_table'
        get 'trips_table'
        get 'services_table'
      end
    end

    # Services
    resources :services, :only => [:index, :destroy, :create, :show, :update]

    # Users
    resources :users, :only => [:index, :create, :destroy, :edit, :update]



  end #Admin

  mount SimpleTranslationEngine::Engine => "/admin/simple_translation_engine"


end #draw
