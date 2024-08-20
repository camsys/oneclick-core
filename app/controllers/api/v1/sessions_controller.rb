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
        Rails.logger.info("Session Params: #{session_params.inspect}")
      
        email = session_params[:email].try(:downcase)
        Rails.logger.info("Email from session_params: #{email.inspect}")
      
        password = session_params[:password]
        Rails.logger.info("Password from session_params: #{password.present? ? 'Provided' : 'Not Provided'}")
      
        ecolane_id = session_params[:ecolane_id]
        Rails.logger.info("Ecolane ID from session_params: #{ecolane_id.inspect}")
      
        county = session_params[:county]
        Rails.logger.info("County after gsub: #{county.inspect}")
      
        dob = session_params[:dob]
        Rails.logger.info("Date of Birth from session_params: #{dob.inspect}")
      
        if ecolane_id
          Rails.logger.info("Processing Ecolane login...")
          ecolane_ambassador = EcolaneAmbassador.new({county: county, dob: dob, ecolane_id: ecolane_id})
          @user = ecolane_ambassador.user
          Rails.logger.info("User found by Ecolane ID: #{@user.inspect}")
      
          if @user
            @user.ensure_authentication_token
            Rails.logger.info("User authentication token ensured")
      
            render status: 200, json: {
              authentication_token: @user.authentication_token,
              email: @user.email,
              first_name: @user.first_name,
              last_name: @user.last_name
            }
          else
            Rails.logger.warn("Invalid Ecolane ID or DOB provided")
            render status: 401, json: {message: "Invalid Ecolane Id or DOB."}
          end
        elsif @user && @user.valid_password?(password)
          Rails.logger.info("User found by email and password is valid")
          sign_in(:user, @user)
          @user.ensure_authentication_token
          render status: 200, json: {
            authentication_token: @user.authentication_token,
            email: @user.email
          }
        else
          Rails.logger.error("Invalid email or password")
          render status: 401,
            json: json_response(:fail, data: {user: "Please enter a valid email address and password"})
        end
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
        params.require(:session).permit(:email, :password, :ecolane_id, :county, :dob)
      end

    end
  end
end
