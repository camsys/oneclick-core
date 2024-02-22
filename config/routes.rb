Rails.application.routes.draw do

  devise_for :users, controllers: { confirmations: 'confirmations' }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  ### JSON API ###
  namespace :api do

    get 'test' => 'api#test' # Dummy action for testing generic ApiController

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
          get  'locales'
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
      put 'itineraries/update_trip_details' => 'trips#update_trip_details'
      # post 'trips/past_trips' => 'trips#index'
      post 'itineraries/plan' => 'trips#create'
      post 'itineraries/select' => 'trips#select'
      post 'itineraries/cancel' => 'trips#cancel'
      post 'itineraries/book' => 'trips#book'
      post 'trip_purposes/list' => 'users#trip_purposes'

      # Users
      resources :users do
        collection do
          get 'profile'
          get 'get_guest_token'
          post 'update'
          post 'password'
          post 'request_reset'
          post 'reset'
          get  'lookup'
          get  'current_balance'
          get  'agency_code'
        end
      end

      devise_scope :user do
        post 'sign_up' => 'registrations#create'
        post 'sign_in' => 'sessions#create'
        post 'sign_out' => 'sessions#destroy'
        delete 'sign_out' => 'sessions#destroy'
      end #users

      resources :services do
        collection do
          get 'ids_humanized'
          get 'hours'
        end
      end

    end #v1


    ### API V2 ###
    namespace :v2 do

      # Agencies
      resources :agencies, only: [:index]

      # Alerts
      resources :alerts, only: [:index, :update]

      # Feedbacks
      resources :feedbacks, only: [:index, :create]

      # Places, Stomping Grounds, Landmarks
      resources :places, only: [:index]
      resources :stomping_grounds, only: [:index, :destroy, :create, :update]

      # Services
      resources :services, only: [:index, :show]

      # Travel Patterns
      resources :travel_patterns, only: [:index]

      # Trips
      resources :trips, only: [:new, :create, :show]
      post 'trips/plan' => 'trips#create'
      post 'trips/plan_multiday' => 'trips#plan_multiday'

      resources :itineraries, only: [] do
        collection do
          post 'email'
        end
      end

        # Purposes
      resources :trips, only: [:show, :create, :new] do
        collection do
          get :trip_purposes
        end
      end

      # Users
      resource :users, only: [:show, :update, :create, :destroy] do
        collection do
          post 'reset_password'
          post 'resend_email_confirmation'
          post 'subscribe'
          post 'unsubscribe'
        end
      end
      post 'sign_up' => 'users#create'
      post 'sign_in' => 'users#new_session'
      delete 'sign_out' => 'users#end_session'
      get 'counties' => 'users#counties'
      get 'trip_purposes', to: 'trips#trip_purposes'

      # Refernet
      if ENV["ONECLICK_REFERNET"]
        post 'oneclick_refernet/create_find_services_history' => 'refernet/services#create_find_services_history'
        post 'oneclick_refernet/update_find_services_history_trip_id' => 'refernet/services#update_find_services_history_trip_id'
        get 'oneclick_refernet/services' => 'refernet/services#index'
        post 'oneclick_refernet/email' => 'refernet/services#email'
        post 'oneclick_refernet/sms' => 'refernet/services#sms'
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
    resources :agencies, only: [:index, :destroy, :create, :show, :update], shallow: true do
    end

    # Booking Windows
    resources :booking_windows

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

    # Funding Sources
    resources :funding_sources

    # Alerts
    resources :alerts, :only => [:index, :destroy, :create, :edit, :update] do
      collection do
        get 'expired'
      end
    end

    resources :custom_geographies, :only => [:index, :create, :new ,:destroy]

    # Geographies
    get 'geographies' => 'geographies#index'
    post 'counties' => 'geographies#upload_counties'
    post 'cities' => 'geographies#upload_cities'
    post 'zipcodes' => 'geographies#upload_zipcodes'
    get 'autocomplete' => 'geographies#autocomplete'
    post 'legacy/custom_geographies/create' => 'geographies#upload_custom_geographies'

    # Landmarks
    resources :landmarks, :only => [:index, :edit, :create, :update, :destroy] do
      collection do
        patch 'update_all'
      end
    end

    # Landmark Sets
    put 'landmark_sets/new' => 'landmark_sets#new'
    put 'landmark_sets/:id/edit' => 'landmark_sets#edit'
    resources :landmark_sets

    resources :od_zones, :only => [:index, :create, :new, :destroy, :show, :edit, :update] do
      collection do
        get 'autocomplete' => 'od_zones#autocomplete'
      end
    end

    # Purposes
    resources :purposes, :only => [:index, :destroy, :create, :edit, :update]
    resources :trip_purposes, controller: :purposes_travel_patterns

    # Reports
    resources :reports, only: [:index] do
      collection do

        # DASHBOARD REPORTS
        post 'dashboard'
        get 'planned_trips_dashboard'
        get 'unique_users_dashboard'
        get 'popular_destinations_dashboard'

        # CSV TABLE DOWNLOADS
        post 'download_table'
        get 'users_table'
        get 'trips_table'
        get 'services_table'
        get 'requests_table'
        get 'feedback_table'
        get 'feedback_aggregated_table'
        get 'find_services_table'

      end
    end

    # Services
    resources :services, :only => [:index, :destroy, :create, :show, :update] do
    end


    resources :service_schedules, :only => [:index, :create, :new, :destroy, :show, :edit, :update]

    resources :travel_patterns, :only => [:index, :create, :new, :destroy, :show, :edit, :update] do
      collection do
        get 'root' => 'travel_patterns#root'
      end
    end


    # Users
    resources :users, :only => [:index, :create, :destroy, :edit, :update] do
      collection do
          get "staff"
          get "travelers"
          post "change_agency"
        end
    end
    
    resources :booking_profiles, only: [:index]

  end #Admin

  mount SimpleTranslationEngine::Engine => "/admin/simple_translation_engine"


end #draw
