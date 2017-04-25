module Api
  module V1
    class SessionsController < Devise::SessionsController
      # acts_as_token_authentication_handler_for User, fallback: :none
      skip_before_action :verify_signed_out_user
      prepend_before_filter :require_no_authentication, :only => [:create ]
      include Devise::Controllers::Helpers
      include JsonResponseHelper::ApiErrorCatcher # Catches 500 errors and sends back JSON with headers.

      # clear_respond_to
      respond_to :json

      # Custom sign_in method renders JSON rather than HTML
      def create
        email = session_params[:email] #params[:email] || (params[:user] && params[:user][:email])
        password = session_params[:password] #params[:password] || (params[:user] && params[:user][:password])
        @user = User.find_by(email: email)

        if @user && @user.valid_password?(password)
          sign_in(:user, @user)
          @user.ensure_authentication_token
          render status: 200, json: {
            authentication_token: @user.authentication_token,
            email: @user.email
          }
        else
          render status: 401,
            json: json_response(:fail, data: {user: "Please enter a valid email address and password"})
        end
        return

      end

      # Custom sign_out method renders JSON and handles invalid token errors.
      def destroy
        user_token = request.headers["X-User-Token"] || params[:user_token] || params[:session][:user_token]
        @user = User.find_by(authentication_token: user_token) if user_token

        if @user
          @user.update_attributes(authentication_token: nil)
          sign_out(@user)
          render status: 200, json: { message: 'User successfully signed out.'}
        else
          render status: 401,
            json: json_response(:fail, data: {user: 'Please provide a valid token.' })
        end
      end

      private

      def session_params
        params[:session] = params.delete :user if params.has_key? :user

        params.require(:session).permit(:email, :password)
      end

    end
  end
end
