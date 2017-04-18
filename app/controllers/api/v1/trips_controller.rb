module Api
  module V1
    class TripsController < ApiController
      before_action :require_authentication, only: [:past_trips, :future_trips, :select, :cancel, :index]

      # GET trips/past_trips
      # Returns past trips associated with logged in user, limit by max_results param
      def past_trips
        past_trips_hash = @traveler.trips.past.limit(params[:max_results] || 10).map {|t| my_trips_hash(t)}
        render status: 200, json: { "trips" => past_trips_hash}
      end

      # GET trips/future_trips
      # Returns future trips associated with logged in user, limit by max_results param
      def future_trips
        future_trips_hash = @traveler.trips.future.limit(params[:max_results] || 10).map {|t| my_trips_hash(t)}
        render status: 200, json: {trips: future_trips_hash}
      end

      # POST trips/, POST itineraries/plan
      def create
        # Create an array of strong trip parameters based on itinerary_request sent
        trips_request = params[:itinerary_request] || []
        trips_params = trips_request.map do |trip|
          purpose = Purpose.find_by(code: params[:trip_purpose] || params[:purpose])
          trip_params(ActionController::Parameters.new({
            trip: {
              origin_attributes: {
                google_place_attributes: trip[:start_location].to_json
              },
              destination_attributes: {
                google_place_attributes: trip[:end_location].to_json
              },
              trip_time: trip[:trip_time].to_datetime,
              arrive_by: (trip[:departure_type] == "arrive"),
              user_id: @traveler && @traveler.id,
              purpose_id: purpose ? purpose.id : nil
            }
          }))
        end

        # Hash of options parameters sent
        options = {
          user_profile: params[:user_profile],
          trip_types: params['modes'] ? params['modes'].map{|m| demodeify(m).to_sym } : TripPlanner::TRIP_TYPES,
          trip_token: params[:trip_token],
          optimize: params[:optimize],
          max_walk_miles: params[:max_walk_miles],
          max_bike_miles: params[:max_bike_miles], # Miles
          max_walk_seconds: params[:max_walk_seconds], # Seconds
          walk_mph: params[:walk_mph] #|| (@traveler.walking_speed ? @traveler.walking_speed.value : 3.0)
        }

        # Create one or more trips based on requests sent.
        @trips = Trip.create(trips_params)

        @trips.each do |trip|
          TripPlanner.new(trip, options).plan
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

      private

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
          origin: MyTripsWaypointSerializer.new(trip.origin).to_hash,
          destination: MyTripsWaypointSerializer.new(trip.destination).to_hash
        }

        # Itinerary Attributes
        itinerary = trip.selected_itinerary
        if itinerary
          itin_hash = {
            arrival: itinerary.end_time.iso8601,
            booking_confirmation: nil, # itinerary.booking_confirmation
            comment: nil, # DEPRECATE? in old OneClick, this just takes the English comment
            cost: itinerary.cost.to_f,
            departure: itinerary.start_time.iso8601,
            duration: itinerary.duration,
            fare: itinerary.cost.to_f,
            id: itinerary.id,
            json_legs: itinerary.legs,
            mode: itinerary.trip_type.nil? ? nil : "mode_#{itinerary.trip_type.to_s}",
            product_id: nil, #itinerary.product_id,
            status: nil, # DEPRECATE?
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

        return {
          "0" => trip_hash.merge(itin_hash).merge(service_hash)
        }
      end

    end
  end
end
