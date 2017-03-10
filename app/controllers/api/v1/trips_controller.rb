module Api
  module V1
    class TripsController < ApiController
      skip_before_action :authenticate_user_from_token!
      before_action :authenticate_user_if_token_present

      # POST trips/, POST itineraries/plan
      def create

        # Create an array of strong trip parameters based on itinerary_request sent
        trips_request = params[:itinerary_request] || []
        trips_params = trips_request.map do |trip|
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
              user_id: @traveler && @traveler.id
            }
          }))
        end

        # Hash of options parameters sent
        options = {
          user_profile: params[:user_profile],
          modes: params['modes'] || ['transit', 'paratransit', 'taxi', 'ride_hailing'],
          purpose: params[:trip_purpose],
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

      private

      def trip_params(parameters)
        parameters.require(:trip).permit(
          {origin_attributes: place_attributes},
          {destination_attributes: place_attributes},
          :trip_time,
          :arrive_by,
          :user_id
        )
      end

      def place_attributes
        [:name, :street_number, :route, :city, :state, :zip, :lat, :lng, :google_place_attributes]
      end

    end
  end
end
