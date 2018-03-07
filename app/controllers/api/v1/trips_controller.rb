module Api
  module V1
    class TripsController < ApiController
      before_action :require_authentication, only: [
        :past_trips, :future_trips, :select, :cancel, :index, :book
      ]
      before_action :ensure_traveler, only: [:create] #If @traveler is not set, then create a guest user account

      # GET trips/past_trips
      # Returns past trips associated with logged in user, limit by max_results param
      def past_trips
        past_trips_hash = @traveler.past_trips(params[:max_results] || 10)
                                   .outbound
                                   .map {|t| my_trips_hash(t)}
        render status: 200, json: {trips: past_trips_hash}
      end

      # GET trips/future_trips
      # Returns future trips associated with logged in user, limit by max_results param
      def future_trips
        future_trips_hash = @traveler.future_trips(params[:max_results] || 10)
                                     .outbound
                                     .map {|t| my_trips_hash(t)}
        render status: 200, json: {trips: future_trips_hash}
      end

      # POST trips/, POST itineraries/plan
      def create

        # Create an array of strong trip parameters based on itinerary_request sent
        api_v1_params = params[:itinerary_request]
        api_v2_params = params[:trips]
        trips_params = {}
        if api_v1_params # This is doing it the old way
          trips_params = api_v1_params.map do |trip|
            purpose = Purpose.find_by(code: params[:trip_purpose] || params[:purpose])
            start_location = trip_location_to_google_hash(trip[:start_location])
            end_location = trip_location_to_google_hash(trip[:end_location])
            trip_params(ActionController::Parameters.new({
              trip: {
                origin_attributes: start_location,
                destination_attributes: end_location,
                trip_time: trip[:trip_time].to_datetime,
                arrive_by: (trip[:departure_type] == "arrive"),
                user_id: @traveler && @traveler.id,
                purpose_id: purpose ? purpose.id : nil
              }
            }))
          end
        elsif api_v2_params # This is doing it the right way
          trips_params = params[:trips].map {|t| trip_params(t) }
        else # For creating a single trip
          trips_params = [trip_params(params)]
        end

        # Hash of options parameters sent
        options = {
          trip_types: params['modes'] ? params['modes'].map{|m| demodeify(m).to_sym } : TripPlanner::TRIP_TYPES,
          user_profile: params[:user_profile]
          # trip_token: params[:trip_token],
          # optimize: params[:optimize],
          # max_walk_miles: params[:max_walk_miles],
          # max_bike_miles: params[:max_bike_miles], # Miles
          # max_walk_seconds: params[:max_walk_seconds], # Seconds
          # walk_mph: params[:walk_mph] #|| (@traveler.walking_speed ? @traveler.walking_speed.value : 3.0)
        }

        #Update the user's profile before planning the trip.
        if @traveler
          @traveler.update_profile(options[:user_profile])
        end

        # Create one or more trips based on requests sent.
        @trips = Trip.create(trips_params)

        @trips.each do |trip|
          trip_planner = TripPlanner.new(trip, options)
          trip_planner.plan
          trip.relevant_purposes = trip_planner.relevant_purposes
          trip.relevant_eligibilities = trip_planner.relevant_eligibilities
          trip.relevant_accommodations = trip_planner.relevant_accommodations
        end

        if @trips
          render status: 200, json: @trips.first, include: ['*.*']
        end
      end

      # POST trips/select, itineraries/select
      # Selects the target itinerary
      def select
        select_itineraries =  params[:select_itineraries] || []
        #Get the itineraries
        results = {}
        select_itineraries.each do |itin|
          itinerary = Itinerary.find_by(id: itin[:itinerary_id].to_i)
          if itinerary && @traveler.owns?(itinerary)
            itinerary.select
            results[itinerary.id] = true
          else
            results[itin[:itinerary_id]] = false
          end
        end
        render status: 200, json: {result: 200, itineraries: results }
      end

      # POST trips/book, POST itineraries/book
      # Selects and books an itinerary via an external booking api
      # If return_time is passed in the booking request, create a return trip
      # as well, and attempt to book it.
      def book

        outbound_itineraries = booking_request_params
        
        responses = booking_request_params
        .map do |booking_request|
          # Find the itinerary identified in the booking request
          itin = Itinerary.find_by(id: booking_request.delete(:itinerary_id))
          itin.try(:select) # Select the itinerary so that the return trip can be built properly
          booking_request[:itinerary] = itin
          next booking_request unless itin
          
          # If a return_time param was passed, build a return itinerary
          return_time = booking_request.delete(:return_time).try(:to_datetime)
          if return_time
            return_itin = ReturnTripPlanner.new(itin.trip, {trip_time: return_time})
                          .plan.try(:selected_itinerary)
            return_booking_request = booking_request.clone.merge({itinerary: return_itin, return: true})
            next [booking_request, return_booking_request]
          else
            next booking_request
          end
        end.flatten.compact # flatten into an array of booking requests
        .map do |booking_request|

          # Pull the itinerary out of the booking_request hash and set up a 
          # default (failure) booking response
          itin = booking_request.delete(:itinerary)       

          response = booking_response_base(itin).merge({booked: false})
                                        
          # BOOK THE ITINERARY, selecting it and storing the response in a booking object
          booking = itin.try(:book, booking_options: booking_request)
          next response unless booking.is_a?(Booking) # Return failure response unless book was successful
          
          # Package it in a response hash as per API V1 docs
          next response.merge(booking_response_hash(booking))
        end
                
        render status: 200, json: {booking_results: responses}
      end

      # POST trips/cancel, itineraries/cancel
      # Unselects and cancels the target itinerary
      def cancel
        results = bookingcancellation_request_params.map do |bc_req|
          itin =  @traveler.itineraries.find_by(id: bc_req[:itinerary_id]) ||
                  @traveler.bookings.find_by(confirmation: bc_req[:booking_confirmation]).try(:itinerary)
          
          response = booking_response_base(itin).merge({success: false})
          next response unless itin
          
          # CANCEL THE ITINERARY, unselecting it and updating the booking object
          cancellation_result = itin.booked? ? itin.cancel : itin.unselect
          
          # Package response as per API V1 docs
          next response.merge(bookingcancellation_response_hash(cancellation_result))
        end
        
        render status: 200, json: {cancellation_results: results}
      end

      # Replicates the email functionality from Legacy (Except for the Ecolane Stuff)
      def email

        email_address = params[:email_address]
        trip_id = params[:trip_id]

        trip = Trip.find(trip_id.to_i)

        UserMailer.user_trip_email([email_address], trip).deliver

        # Also should improve the JSON response to handle successfully and failed email calls`
        render json: {result: 200}

      end

      protected
      
      def booking_request_params
        params.require(:booking_request).map do |p|
          p.permit(
            :itinerary_id,
            :guests,
            :purpose,
            :pickup_unit_number,
            :dropoff_unit_number,
            :attendants,
            :return_time,
            :mobility_devices
          )
        end
      end
      
      def bookingcancellation_request_params
        params.require(:bookingcancellation_request).map do |p|
          p.permit(
            :itinerary_id,
            :booking_confirmation
          )
        end
      end

      def trip_params(parameters)
        parameters.require(:trip).permit(
          {origin_attributes: place_attributes},
          {destination_attributes: place_attributes},
          :trip_time,
          :arrive_by,
          :user_id,
          :purpose_id
        )
      end

      def place_attributes
        [:name, :street_number, :route, :city, :state, :zip, :lat, :lng, :google_place_attributes]
      end

      # Converts mode code from Legacy to OCC
      # Removes "mode_" from the start of mode code string
      # Also lets mode_ride_hailing act as an alias for mode_uber
      def demodeify(string)
        string.sub("mode_", "").sub("ride_hailing","uber")
      end
      
      # Converts mode code from OCC to Legacy
      # subs "uber" for "ride_hailing", and prepends "mode_"
      def remodeify(code)
        "mode_" + code.to_s.sub("uber", "ride_hailing")
      end

      # Serializes trips in the hash format demanded by the past_trips and future_trips
      # calls (i.e. the My Trips section of the UI)
      def my_trips_hash(trip)
        trips_hash = { "0" => trip_hash(trip) }
        trips_hash["1"] = trip_hash(trip.next_trip) if trip.next_trip
        trips_hash
      end
      
      def trip_hash(trip)
        trip_hash = {}
        itin_hash = {}
        service_hash = {
          service_name: ""
        }

        # Trip attributes
        trip_hash = {
          trip_id: trip.id,
          origin: WaypointSerializer.new(trip.origin).to_hash,
          destination: WaypointSerializer.new(trip.destination).to_hash
        }

        # Itinerary Attributes
        itinerary = trip.selected_itinerary
        if itinerary
          itin_hash = {
            arrival: itinerary.end_time ? itinerary.end_time.iso8601 : nil,
            booking_confirmation: itinerary.booking_confirmation,
            comment: nil, # DEPRECATE? in old OneClick, this just takes the English comment
            cost: itinerary.cost.to_f,
            departure: itinerary.start_time ? itinerary.start_time.iso8601 : nil,
            duration: itinerary.duration,
            fare: itinerary.cost.to_f,
            id: itinerary.id,
            json_legs: itinerary.legs,
            mode: itinerary.trip_type.nil? ? nil : remodeify(itinerary.trip_type),
            product_id: nil, #itinerary.product_id,
            status: "active", # DEPRECATE?
            transfers: nil, #itinerary.transfers, # DEPRECATE?
            transit_time: itinerary.transit_time,
            wait_time: nil, #itinerary.wait_time, # WAIT TIME?
            walk_distance: nil, #itinerary.walk_distance, # DEPRECATE?
            walk_time: itinerary.walk_time
          }

          # Service Attributes
          svc = itinerary.service
          if svc
            service_hash = {
              logo_url: svc.logo ? ActionController::Base.helpers.asset_path(svc.logo.thumb.url.to_s) : nil,
              phone: svc.phone,
              service_comments: I18n.available_locales.map {|loc| [loc, svc.description(loc)] }.to_h,
              service_name: svc.name,
              url: svc.url
            }
          end

        end

        combined_hash = trip_hash.merge(itin_hash).merge(service_hash)
      end

      # Builds a location hash out of the location param, packaging it as a google place hash
      def trip_location_to_google_hash(location)
        { google_place_attributes: location.to_json }
      end
      
      # Returns the base hash for booking action responses
      def booking_response_base(itinerary)
        {
          trip_id: itinerary.try(:trip).try(:id),
          itinerary_id: itinerary.try(:id)
        }
      end
      
      # Makes an API V1 booking response hash from a booking object
      def booking_response_hash(booking)
        itin = booking.itinerary
        
        case booking.type_code
        when 'ride_pilot', :ride_pilot
          pickup_time = booking.details.try(:[], "pickup_time").try(:to_datetime) || itin.start_time
          # NOTE: Typo in RidePilot codebase means key is "dropff_time" rather than "dropoff_time". Should be patched by 8/31/17.
          dropoff_time = (booking.details.try(:[], "dropff_time") ||
                          booking.details.try(:[], "dropoff_time"))
                          .try(:to_datetime) || pickup_time + itin.duration.seconds
          confirmation_id = booking.details.try(:[], "trip_id")
          return {
            booked: true,
            confirmation: confirmation_id, # it needs both of these 
            confirmation_id: confirmation_id, # for some reason
            wait_start: (pickup_time - 15.minutes).iso8601,
            wait_end: (pickup_time + 15.minutes).iso8601,
            arrival: dropoff_time.iso8601,
            message: "Booking Status: #{booking.status}",
            negotiated_duration: ((dropoff_time - pickup_time) * 1.day).round # Returns duration in seconds
          }
        when 'trapeze', :trapeze
          pickup_time = itin.start_time
          # NOTE: Typo in RidePilot codebase means key is "dropff_time" rather than "dropoff_time". Should be patched by 8/31/17.
          dropoff_time = pickup_time + itin.duration.seconds
          confirmation_id = booking.confirmation
          return {
            booked: true,
            confirmation: confirmation_id, # it needs both of these 
            confirmation_id: confirmation_id, # for some reason
            wait_start: (pickup_time - 15.minutes).iso8601,
            wait_end: (pickup_time + 15.minutes).iso8601,
            arrival: dropoff_time.iso8601,
            message: "Booking Status: #{booking.status}",
            negotiated_duration: ((dropoff_time - pickup_time) * 1.day).round # Returns duration in seconds
          }
        else
          return {}
        end
      end
      
      # Makes an API V1 bookingcancellation response hash from a booking object
      def bookingcancellation_response_hash(booking)
        case booking.try(:type_code)
        when :ride_pilot
          return {
            success: true,
            confirmation_id: booking.confirmation
          }
        else
          return {
            success: true
          }
        end        
      end

    end
  end
end
