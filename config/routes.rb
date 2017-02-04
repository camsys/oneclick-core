Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post 'sign_up' => 'registrations#create'
      end

      resources :places do
        collection do
          get 'search'
        end
      end #places 
    
    end #v1
  end #api

  #Built in Views
  resources :configs, :only => [:index] do
    collection do
      patch 'set_open_trip_planner'
    end
  end #Built in Views

  resources :landmarks, :only => [:index] do
    collection do
      
    end
  end #Built in Views

end #draw
