Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do

    namespace :v1 do
      devise_scope :user do
        post 'sign_up' => 'registrations#create'
        post 'sign_in' => 'sessions#create'
        delete 'sign_out' => 'sessions#destroy'
      end

      resources :places do
        collection do
          get 'search'
        end
      end #places

      resources :trips, only: [:create]
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
    resources :services, :only => [:index]

  end #Admin

end #draw
