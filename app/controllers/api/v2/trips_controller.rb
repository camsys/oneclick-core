module Api
  module V2
    class TripsController < ApiController
      before_action :ensure_traveler, only: [:create] #If @traveler is not set, then create a guest user account

      # GET trips/:id
      # Gets an already planned trip. Must authenticate user.
      def show
        @trip = Trip.find(params[:id])
        
        # Don't return the trip unless the traveler is authenticated OR it is associated with a guest user
        unless((@traveler.present? && @trip.user == @traveler) || @trip.user.guest?)
          @trip = nil
        end
        
        if @trip
          render success_response(@trip, serializer_opts: {include: ['*.*.*']})
        else
          render(fail_response(status: 404, message: "Not found"))
        end
      end

      def new
        render success_response(Trip.new, serializer_opts: {include: ['*.*.*']})
      end

      # POST trips/
      # POST trips/plan
      # Creates a new trip and associated itineraries based on the passed params,
      # and returns JSON with information about that trip.
      def create
              
        # Update the traveler's user profile before planning the trip.
        # and return the accommodations/ eligibilities
        update_traveler_profile
        
        # Set purpose_id in trip_params
        # Note: not used in 211 ride
        set_trip_purpose

        # Initialize a trip based on the params
        @trip = Trip.create(trip_params)
        @trip.user = @traveler
        @trip_planner = TripPlanner.new(@trip, trip_planner_options)

        # Plan the trip (build itineraries and save it)
        # NOTE: check how different OCC instances that use the V2 API handle trip accommodations and eligibilities
        # - make sure this doesn't break anything in other one click instances(FMR doesn't use eligibilities/ accommodations so not really checking that)
        if @trip_planner.plan
          # Pull accommodations and eligibilities from the user's profile
          user_acc = @trip.user.accommodations
          user_elig = @trip.user.eligibilities

          @trip.relevant_purposes = @trip_planner.relevant_purposes
          # Set trip eligibilities and accommodations based on both the trip planner and the user profile
          # Using array filter as Trip Planner returns an array of eligibilities not an Active Record Collection
          @trip.relevant_eligibilities = @trip_planner.relevant_eligibilities.select {|elig| user_elig.include?(elig)}
          @trip.relevant_accommodations = @trip_planner.relevant_accommodations.where(id: user_acc.pluck(:id))
          @trip.user_age = @trip.user.age
          @trip.user_ip = @trip.user.current_sign_in_ip
          @trip.save
          render success_response(@trip, serializer_opts: {include: ['*.*.*']})
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
        stringify_google_place_attributes(params).require(:trip).permit(
          {origin_attributes: place_attributes},
          {destination_attributes: place_attributes},
          :trip_time,
          :arrive_by,
          :user_id,
          :purpose_id
        )
      end

      def place_attributes
        [:name, :street_number, :route, :city, :county,:state, :zip, :lat, :lng, :google_place_attributes]
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
          trip_types: params[:trip_types].try(:map, &:to_sym), # convert strings to symbols
          only_filters: params[:only_filters].try(:map, &:to_sym),
          except_filters: params[:except_filters].try(:map, &:to_sym)
        }
      end
      
      # Converts google place attributes params to JSON strings
      def stringify_google_place_attributes(params)
        
        [:origin_attributes, :destination_attributes].each do |place|
          if params[:trip][place][:google_place_attributes].present?
            google_place_json = params[:trip][place][:google_place_attributes].to_json
            params[:trip][place][:google_place_attributes] = google_place_json
          end
        end

        return params
      end

    end
  end
end
