Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do

    namespace :v1 do
      devise_scope :user do
        post 'sign_up' => 'registrations#create'
      end
    end

    namespace :v2 do
      devise_scope :user do
        post 'sign_up' => 'registrations#create'
      end
    end

  end

end
