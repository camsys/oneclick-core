module Api
  module V1
    class TripsController < ApiController
      skip_before_action :authenticate_user_from_token!
      before_action :authenticate_user_if_token_present

      # POST trips/, POST itineraries/plan
      def create
        # user_profile json A json that updates the user's profile. This will be done before the plan call is run.
        # trip_purpose string
        # trip_token:string
        # optimize string can be ‘TIME’, ‘TRANSFERS’, or ‘WALKING’, Set to ‘TIME’ time to minimize total trip time. Set to ‘TRANSFERS’ to minimize transfers, or set to ‘WALKING’ to minimize time spent walking. If not included, ‘TIME’ is assumed.
        # itinerary_requests array of trip requests
        # segment_index int (starting with 0)
        # start_location Google Place
        # end_location: Google Place
        # trip_time ISO8601 DateTime
        # departure_type string (valid values are ‘arrive’, ‘depart’)
        # max_walk_miles (optional) float Maximum distance the traveler is willing to walk. 2 Miles is default.
        # max bicycle_miles (optional) float Maximum distance the traveler is willing to bike. 5 miles is default.
        # max_walk_seconds (optional) integer Maximum time the traveler is willing to walk. Infinity is default.
        # walk_mph (optional) float Traveler's walking speed in MPH (Used to calculate maximum distance when max_walk_seconds is specified. Also sent to OpenTripPlanner to determine trip times. Default is 3MPH. For travelers with a walking speed set in their profiles, this parameter will overwrite that parameter for the given trip.
        # num_itineraries (optional) integer The maximum number of itineraries to be returned from OTP. The default is 3.
        # modes (optional) array an array of strings for the modes that you want returned. For example ['mode_transit', 'mode_taxi', 'mode_paratransit', 'mode_bicycle', 'mode_bicycle_transit']. If modes is NULL, mode_transit, and mode_paratransit will be the default.


        # #Unpack params
        # user_profile = params[:user_profile]
        # modes = params['modes'] || ['mode_transit', 'mode_paratransit', 'mode_taxi', 'mode_ride_hailing']
        # trip_parts = params[:itinerary_request]
        # purpose = params[:trip_purpose]
        # trip_token = params[:trip_token]
        # optimize = params[:optimize]
        # max_walk_miles = params[:max_walk_miles]
        # max_bike_miles = params[:max_bike_miles] # Miles
        # max_walk_seconds = params[:max_walk_seconds] # Seconds
        # walk_mph = params[:walk_mph] #|| (@traveler.walking_speed ? @traveler.walking_speed.value : 3.0)


        puts "CREATING TRIP: ", params.ai, @current_user.ai
        @trip = Trip.create(params[:trip])
        puts @trip.ai
        if @trip
          render status: 200, json: @trip
        end
      end
    end
  end
end
