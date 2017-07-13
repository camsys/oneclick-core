module Api
  module V2
    class TripsController < ApiController
      before_action :current_or_guest_user, only: [:create] #If @traveler is not set, then create a guest user account

      # POST trips/
      def create

        # Hash of options parameters sent
        options = {
          trip_types: params[:trip_types] || TripPlanner::TRIP_TYPES,
          user_profile: params[:user_profile]
        }

        #Update the user's profile before planning the trip.
        if @traveler
          @traveler.update_profile(options[:user_profile])
        end

        # Create one or more trips based on requests sent.
        @trip = Trip.create(trip_params)

        trip_planner = TripPlanner.new(@trip, options)
        if trip_planner.plan
          @trip.relevant_purposes = trip_planner.relevant_purposes
          @trip.relevant_eligibilities = trip_planner.relevant_eligibilities
          @trip.relevant_accommodations = trip_planner.relevant_accommodations
          render success_response(@trip)
        end
        
      end

      protected

      def trip_params
        params.require(:trip).permit(
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

    end
  end
end
