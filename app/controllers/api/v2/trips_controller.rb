module Api
  module V2
    class TripsController < ApiController
      before_action :current_or_guest_user, only: [:create] #If @traveler is not set, then create a guest user account

      # POST trips/
      # POST trips/plan
      # Creates a new trip and associated itineraries based on the passed params,
      # and returns JSON with information about that trip.
      def create

        # Update the traveler's user profile before planning the trip.        
        update_traveler_profile
        
        # Set purpose_id in trip_params
        set_trip_purpose

        # Initialize a trip based on the params
        @trip = Trip.new(trip_params)
        trip_planner = TripPlanner.new(@trip, trip_planner_options)
        
        # Plan the trip (build itineraries and save it)
        if trip_planner.plan
          @trip.relevant_purposes = trip_planner.relevant_purposes
          @trip.relevant_eligibilities = trip_planner.relevant_eligibilities
          @trip.relevant_accommodations = trip_planner.relevant_accommodations
          render success_response(@trip)
        end
        
      end
      

      # POST trips/plan_multiday
      # Similar to the normal plan call, except accepts an array of trip times.
      # Returns a trip for each of the passed times.
      # Also accepts lists of eligibilities and accommodations.
      def plan_multiday
        trip_times = params[:trip_times]
        mtp = MultidayTripPlanner.new(Trip.create(trip_params), trip_times, trip_planner_options)
        @trips = mtp.plan
        render success_response(@trips)
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
      
      # Updates the traveler's profile if the traveler exists and user_profile param was passed
      def update_traveler_profile
        if @traveler && params[:user_profile]
          @traveler.update_profile(params.delete(:user_profile))
        end
      end
      
      # Pulls a purpose code out of trip params and replaces it with purpose_id
      def set_trip_purpose
        if params[:trip] && params[:trip][:purpose]
          params[:trip][:purpose_id] = Purpose.find_by(code: params[:trip].delete(:purpose)).try(:id)
        end
      end
      
      # Pulls out TripPlanner options from the params
      def trip_planner_options
        {
          trip_types: params.delete(:trip_types).try(:map, &:to_sym) # convert strings to symbols
        }
      end

    end
  end
end
