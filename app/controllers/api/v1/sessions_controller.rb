module Api
  module V1
    class SessionsController < Devise::SessionsController
      # acts_as_token_authentication_handler_for User, fallback: :none
      skip_before_action :verify_signed_out_user

      # clear_respond_to
      respond_to :json

      # Custom sign_in method renders JSON rather than HTML
      def create
        self.resource = warden.authenticate!(auth_options)
        sign_in(resource_name, resource)
        render json: {
          authentication_token: resource.authentication_token,
          email: resource.email
        } # Failure response is rendered in api_auth_failure_app.rb
      end

      # Custom sign_out method renders JSON and handles invalid token errors.
      def destroy
        user_token = request.headers["X-User-Token"] || params[:user_token] || params[:session][:user_token]
        @user = User.find_by(authentication_token: user_token) if user_token

        if @user
          @user.update_attributes(authentication_token: nil)
          render status: 200, json: { message: 'User successfully signed out.'}
        else
          render status: 401, json: { error: 'Please provide a valid token.' }
        end
      end

    end
  end
end
