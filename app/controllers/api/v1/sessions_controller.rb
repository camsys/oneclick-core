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
        Rails.logger.info "Received params: #{params.inspect}"
        email = session_params[:email].try(:downcase) #params[:email] || (params[:user] && params[:user][:email])
        password = session_params[:password] #params[:password] || (params[:user] && params[:user][:password])
        @user = User.find_by(email: email)
        ecolane_id = session_params[:ecolane_id]
        county = session_params[:county]
        dob = session_params[:dob]
        service_id = session_params[:service_id]
        Rails.logger.info "service_id: #{service_id}"
        Rails.logger.info "ecolane_id: #{ecolane_id}"
        Rails.logger.info "county: #{county}"
        Rails.logger.info "dob: #{dob}"
        Rails.logger.info "email: #{email}"

        ############## Custom Ecolane Stuff ######################
        if ecolane_id
          ecolane_ambassador = EcolaneAmbassador.new({county: county, dob: dob, ecolane_id: ecolane_id, service_id: service_id})
          
          @user = ecolane_ambassador.user
          if @user
            unless @user.primary_service_id == service_id.to_i
              render status: 401, json: { message: "Unauthorized access to the selected service." }
              return
            end
            #Last Trip
            @user.verify_default_booking_presence
            last_trip = @user.trips.order('created_at').last
            #If this is a round trip, return the first part instead of the last part
            if last_trip and last_trip.previous_trip 
              last_trip = last_trip.previous_trip
            end
            if last_trip and last_trip.origin and last_trip.destination
              last_origin = last_trip.origin.google_place_hash
              last_destination = last_trip.destination.google_place_hash
            end
            sign_in(:user, @user)
            @user.ensure_authentication_token
            days_to_sync = 3
            # if user is new to db, run 14 day sync (user may have called in rides up to now)
            if (Time.now - @user.created_at) < 10.minutes
              days_to_sync = 14
            end
            puts "Syncing user from #{days_to_sync} days ago"
            @user.sync days_to_sync

            render status: 200, json: {
              authentication_token: @user.authentication_token,
              email: @user.email,
              first_name: @user.first_name,
              last_name: @user.last_name,
              last_origin: last_origin || nil,
              last_destination: last_destination || nil
            }
          else 
            render status: 401, json: {message: "Invalid Ecolane Id or DOB."}
          end

        elsif @user && @user.valid_password?(password)
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


        Rails.logger.info "service_id: #{service_id}"

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
