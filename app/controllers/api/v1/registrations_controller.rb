module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # POST sign_up
      def create

        # Shim to make old API call work properly
        if params[:user].nil?
          params[:user] = {
            email: params[:email],
            password: params[:password],
            password_confirmation: params[:password_confirmation],
            first_name: params[:first_name],
            last_name: params[:last_name]
          }
        end

        super

      end
    end
  end
end
