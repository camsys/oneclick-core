module Api
  module V1
    class TripsController < ApiController
      before_action :require_authentication, only: [:past_trips, :future_trips, :select, :cancel, :index]
      before_action :current_or_guest_user, only: [:create] #If @traveler is not set, then create a guest user account

      # GET trips/past_trips
      # Returns past trips associated with logged in user, limit by max_results param
      def past_trips
        past_trips_hash = @traveler.past_trips(params[:max_results] || 10).map {|t| my_trips_hash(t)}
        render status: 200, json: {trips: past_trips_hash}
      end

      # GET trips/future_trips
      # Returns future trips associated with logged in user, limit by max_results param
      def future_trips
        future_trips_hash = @traveler.future_trips(params[:max_results] || 10).map {|t| my_trips_hash(t)}
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

      def select
        select_itineraries =  params[:select_itineraries] || []
        #Get the itineraries
        results = {}
        select_itineraries.each do |itin|
          itinerary = Itinerary.find_by(id: itin[:itinerary_id].to_i)
          if @traveler.owns? itinerary
            itinerary.select
            results[itinerary.id] = true
          else
            results[itin[:itinerary_id]] = false
          end
        end
        render status: 200, json: results
      end

      def cancel
        bookingcancellation_request = params[:bookingcancellation_request] || []
        # At the moment, this only handles unselecting itineraries.  True cancelling is not yet supported.
        results = []
        bookingcancellation_request.each do |bc|
          itinerary = Itinerary.find_by(id: bc[:itinerary_id].to_i)
          if @traveler.owns? itinerary
            itinerary.unselect
            #results[itinerary.id] = true
            results.append({trip_id: itinerary.trip.id, itinerary_id: bc[:itinerary_id], success: true, confirmation_id: nil})
          else
            results.append({trip_id: nil, itinerary_id: bc[:itinerary_id], success: false, confirmation_id: nil})
          end
        end
        render status: 200, json: {cancellation_results: results}
      end

      protected

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

      # Removes "mode_" from the start of mode code string
      # Also lets mode_ride_hailing act as an alias for mode_uber
      def demodeify(string)
        string.sub("mode_", "").sub("ride_hailing","uber")
      end

      # Serializes trips in the hash format demanded by the past_trips and future_trips
      # calls (i.e. the My Trips section of the UI)
      def my_trips_hash(trip)

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
            booking_confirmation: nil, # itinerary.booking_confirmation
            comment: nil, # DEPRECATE? in old OneClick, this just takes the English comment
            cost: itinerary.cost.to_f,
            departure: itinerary.start_time ? itinerary.start_time.iso8601 : nil,
            duration: itinerary.duration,
            fare: itinerary.cost.to_f,
            id: itinerary.id,
            json_legs: itinerary.legs,
            mode: itinerary.trip_type.nil? ? nil : "mode_#{itinerary.trip_type.to_s}",
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
              service_comments: svc.comments.map{|c| [c.locale, c.comment]}.to_h,
              service_name: svc.name,
              url: svc.url
            }
          end

        end

        combined_hash = trip_hash.merge(itin_hash).merge(service_hash)

        return {
          "0" => combined_hash
        }
      end

      # Builds a location hash out of the location param, packaging it as a google place hash
      def trip_location_to_google_hash(location)
        { google_place_attributes: location.to_json }
      end

    end
  end
end
