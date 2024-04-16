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
        email = session_params[:email].try(:downcase) # Retrieve and downcase the email from session parameters
        password = session_params[:password] # Retrieve password from session parameters
        @user = User.find_by(email: email)
        ecolane_id = session_params[:ecolane_id]
        selected_service_id = session_params[:service_id].to_i  # Convert the selected service ID to integer for comparison
        county = session_params[:county]
        dob = session_params[:dob]
      
        # Custom Ecolane user check and handling
        if ecolane_id
          ecolane_ambassador = EcolaneAmbassador.new({county: county, dob: dob, ecolane_id: ecolane_id})
          @user = ecolane_ambassador.user
          if @user
            # Ensure the user has permission to access the selected service
            if @user.services.map(&:id).include?(selected_service_id)
              service_id = selected_service_id
            else
              render status: 401, json: { message: "Unauthorized service access." }
              return
            end
      
            @user.verify_default_booking_presence
            last_trip = @user.trips.order('created_at').last
            # Handle round trips: return the first part instead of the last
            last_trip = last_trip.previous_trip if last_trip && last_trip.previous_trip
            last_origin = last_trip&.origin&.google_place_hash
            last_destination = last_trip&.destination&.google_place_hash
      
            sign_in(:user, @user)
            @user.ensure_authentication_token
            sync_days = (Time.now - @user.created_at) < 10.minutes ? 14 : 3
            @user.sync sync_days
      
            render status: 200, json: {
              authentication_token: @user.authentication_token,
              email: @user.email,
              service_id: service_id,
              first_name: @user.first_name,
              last_name: @user.last_name,
              last_origin: last_origin,
              last_destination: last_destination
            }
          else 
            render status: 401, json: {message: "Invalid Ecolane Id or DOB."}
          end
      
        elsif @user && @user.valid_password?(password)
          # Validate that the user can access the selected service
          if @user.services.map(&:id).include?(selected_service_id)
            sign_in(:user, @user)
            @user.ensure_authentication_token
            render status: 200, json: {
              authentication_token: @user.authentication_token,
              email: @user.email,
              service_id: selected_service_id  # Return the validated and selected service ID
            }
          else
            render status: 401, json: { message: "Unauthorized service access." }
          end
        else
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
        params.require(:session).permit(:email, :password, :ecolane_id, :county, :dob, :service_id)
      end

    end
  end
end
