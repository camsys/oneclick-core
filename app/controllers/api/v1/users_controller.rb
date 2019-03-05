module Api
  module V1
    class UsersController < ApiController
      before_action :require_authentication, only: [:update, :trip_purposes]
      before_action :ensure_traveler, only: [:get_guest_token] #If @traveler is not set, then create a guest user account

      # Sends back a profile hash via the API::V1::UserSerializer
      def profile
        render json: @traveler
      end

      # Update's the logged-in user's profile
      def update
        response = { message: "" }

        updated_successfully = @traveler.update_profile(params)

        # Check if booking profiles were successfully updated and authenticated, and prepare response
        if params["booking"].is_a?(Array)
          booking_authenticated = params["booking"].all? do |booking|
            @traveler.booking_profiles.find_by(service_id: booking["service_id"]).try(:authenticate?)
          end
          response[:booking] = booking_authentication_response(booking_authenticated) 
        else
          booking_authenticated = true
        end
        
        if updated_successfully && booking_authenticated
          response[:message] = "User Updated Successfully"
          render status: 200, json: response
        else
          response[:message] = "Unable to update user profile due the following error: #{@traveler.errors.messages}" 
          render status: 400, json: response
        end
      end

      # Used by API/v1 to create guest users on command
      def get_guest_token
        @traveler.ensure_authentication_token # Guest users do not have an auth token by default, so we must generate one
        render status: 200, json: {email: @traveler.email, authentication_token: @traveler.authentication_token}
      end

      # Replicate Password Reset Call from Legacy
      # It's ugly, but behaves exactly as the old call did.
      def password

        if params[:password].nil? or params[:password_confirmation].nil?
          render status: 400, json: {result: false, message: "Missing password or password confirmation."}
          return
        end

        if params[:password] != params[:password_confirmation]
          render status: 406, json: {result: false, message: 'Passwords do not match.'}
          return
        end

        @traveler.password = params[:password]
        @traveler.password_confirmation = params[:password_confirmation]

        result = @traveler.save

        if result
          render status: 200, json: {result: result, message: 'Success'}
        else
          render status: 406, json: {result: result, message: 'Unacceptable Password'}
        end

        return
      end
      
      # Requests a password reset by user email, and sets an email with a reset link.
      def request_reset
        @traveler = User.find_by(email: params[:email])
        if @traveler.nil?
          render status: 404, json: {message: "User not found"}
          return
        else
          @traveler.send_api_v1_reset_password_instructions
          render status: 200, json: {message: "Password reset instructions sent to #{@traveler.email}."}
          return
        end
      end
      
      # Resets user password based on a token. Duplicates legacy 1-Click reset call.
      def reset
        @token = Devise.token_generator.digest(User, :reset_password_token, params[:reset_password_token])
        @traveler = User.find_by_reset_password_token(@token)
        unless (@traveler && @traveler.reset_password_period_valid?)
          render status: 403, json: {message: "Invalid password reset token."}
          return
        end

        if params[:password].nil? or params[:password_confirmation].nil?
          render status: 400, json: {result: false, message: "Missing password or password confirmation."}
          return
        end

        if params[:password] != params[:password_confirmation]
          render status: 406, json: {result: false, message: 'Passwords do not match.'}
          return
        end

        @traveler.password = params[:password]
        @traveler.password_confirmation = params[:password_confirmation]

        result = @traveler.save

        if result
          render status: 200, json: {result: result, message: 'Success'}
        else
          render status: 406, json: {result: result, message: 'Unacceptable Password'}
        end

        return
      end

      #Built to Support Ecolane API/V1
      def trip_purposes

        #If the user is registered with a service, use his/her trip purposes
        trip_purposes  = []
        booking_profile = @traveler.booking_profiles.first
        if @traveler and booking_profile
          begin
            trip_purposes = booking_profile.booking_ambassador.get_trip_purposes
          rescue Exception=>e
            trip_purposes = []
          end
        end
        purposes = trip_purposes.sort

        #Append extra information to Top Trip Purposes Array
        bookings = @traveler.bookings.where('bookings.created_at > ?', Time.now - 6.months).order(created_at: :desc)
        top_purposes = []
        bookings.each do |booking|
          purpose = booking.details.try(:with_indifferent_access).try(:[],:purpose) 
          if purpose and not purpose.in? top_purposes
            #top_purposes << #{name: purpose, code: purpose, sort_order: index}
            top_purposes << purpose
          end
          if top_purposes.length > 3
            break
          end
        end

        #Make sure Top Purposes are still allowed
        top_purposes = top_purposes.map{ |x| (x.in? purposes) ? x : 'DELETE' }
        top_purposes -= ['DELETE']

        #Delete Duplicates
        purposes = purposes.map{ |x| (x.in? top_purposes) ? 'DELETE' : x }
        purposes -= ['DELETE']

        purposes_hash = []
        purposes.each_with_index do |p, i|
          purposes_hash << {name: p, code: p, sort_order: i}
        end

        top_purposes_hash = []
        top_purposes.each_with_index do |p, i|
          top_purposes_hash << {name: p, code: p, sort_order: i}
        end

        hash = {top_trip_purposes: top_purposes_hash, trip_purposes: purposes_hash}
        render json: hash

      end
      
      private
      
      # Returns a hash for responding to user authentication attempts
      def booking_authentication_response(success)
        {
          result: success,
          message: success ? "Third-party booking profile(s) successfully authenticated." : "Third-party booking authentication failed.",
          prebooking_questions: prebooking_questions_response
        }
      end

      def prebooking_questions_response
        #TODO: This returns all of the prebooking questions for all of the users services
        # We could change it so that it only sends questions for the new services.
        response = {}
        @traveler.booking_profiles.each do |bp|
          response[bp.service_id] = bp.prebooking_questions
        end 
        response 
      end

    end
  end
end
