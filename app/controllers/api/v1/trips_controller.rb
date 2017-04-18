module Api
  module V1
    class TripsController < ApiController
      before_action :require_authentication, only: [:select, :cancel]

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

    end
  end
end
