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
        past_trips_hash = @traveler.past_trips(params[:max_results] || 25)
                                   .outbound
                                   .map {|t| filter_trip_name(t)}
        render status: 200, json: {trips: past_trips_hash}
      end

      # GET trips/future_trips
      # Returns future trips associated with logged in user, limit by max_results param
      def future_trips
        # Only return trips that have been booked properly
        future_trips_with_booking = @traveler.future_trips(params[:max_results] || 25).select do |trip|
          trip.booking.present? && trip.booking.confirmation.present?
        end

        future_trips_hash = future_trips_with_booking.map { |t| filter_trip_name(t) }
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
            external_purpose = params[:trip_purpose]
            start_location = trip_location_to_google_hash(trip[:start_location])
            end_location = trip_location_to_google_hash(trip[:end_location])
            note = params[:note]
            
            trip_params(ActionController::Parameters.new({
              trip: {
                origin_attributes: start_location,
                destination_attributes: end_location,
                trip_time: trip[:trip_time].to_datetime,
                arrive_by: (trip[:departure_type] == "arrive"),
                user_id: @traveler && @traveler.id,
                purpose_id: purpose ? purpose.id : nil,
                external_purpose: external_purpose,
                details: trip[:details],
                note: note
            }
            }))
          end
        elsif api_v2_params
          trips_params = params[:trips].map do |t|
            # Assign the original_name to name in google_place_attributes if present
            if t.dig(:origin_attributes, :google_place_attributes, :original_name).present?
              t[:origin_attributes][:google_place_attributes][:name] = t[:origin_attributes][:google_place_attributes][:original_name]
            end

            if t.dig(:destination_attributes, :google_place_attributes, :original_name).present?
              t[:destination_attributes][:google_place_attributes][:name] = t[:destination_attributes][:google_place_attributes][:original_name]
            end

            trip_params(t)
          end
        else
          # Handling for a single trip
          trips_params = [trip_params(params)]
        end

        # Hash of options parameters sent
        options = {
          trip_types: params['modes'] ? params['modes'].map{|m| demodeify(m).to_sym } : TripPlanner::TRIP_TYPES,
          user_profile: params[:user_profile],
          companions: params[:companions],
          assistant: params[:assistant],
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
        
        # Check if there re existing trips for this user at same times and locations.
        # If there is an existing trip, update its itineraries in case changes were made.
        # ie: Companions have been added and the cost needs to be recalculated
        Trip.transaction do
          @trips = trips_params.map do |trip_param|
            # To be considered an existing trip it should have the same Origin, Destination,
            # Trip time, Arrival time, and User as the requested trip.
            # Ignore any trips with selected itineraries, as these are already booked.
            outbound_trip = trips_params.sort_by { |trip_param| trip_param[:trip_time] }.first
            conflicting_trip = Trip.where(trip_time: outbound_trip[:trip_time],
                                            arrive_by: outbound_trip[:arrive_by],
                                            user_id: outbound_trip[:user_id],
                                            previous_trip_id: nil)
                                    .where.not(selected_itinerary_id: nil)
                                    .includes(selected_itinerary: :booking)
                                    .detect { |possible_trip| possible_trip.selected_itinerary.booking.booked? }
  
            return render(status: 409, json: {}, include: ['*.*']) if (conflicting_trip)
            
            origin_place = Place.attrs_from_google_place(trip_param[:origin_attributes][:google_place_attributes])
            destination_place = Place.attrs_from_google_place(trip_param[:destination_attributes][:google_place_attributes])
      
            # Restore the original full names for origin and destination
            [origin_place, destination_place].each do |place|
              if place[:original_name].present?
                place[:name] = place[:original_name]
              end
            end

            return render(status: 404, json: origin_place) unless Landmark.place_exists?(origin_place)
            return render(status: 404, json: destination_place) unless Landmark.place_exists?(destination_place)

            existing_trip = Trip.where(trip_time: trip_param[:trip_time],
                                        arrive_by: trip_param[:arrive_by],
                                        user_id: trip_param[:user_id],
                                        selected_itinerary_id: nil)
                                .order(updated_at: :desc)
                                .detect { |trip|
                                  trip.origin.lat.to_f.round(6) == origin_place[:lat].to_f.round(6) &&
                                  trip.origin.lng.to_f.round(6) == origin_place[:lng].to_f.round(6) &&
                                  trip.destination.lat.to_f.round(6) == destination_place[:lat].to_f.round(6) &&
                                  trip.destination.lng.to_f.round(6) == destination_place[:lng].to_f.round(6)
                                }
            
            existing_trip ? existing_trip : Trip.create!(trip_param)
          end.sort_by{ |t| t.trip_time }

          # Now that trips have either been found or created, it's time to make sure they're up to date
          previous_trip = nil
          @trips.each do |trip|
            Rails.logger.info "Trip being created: Origin: #{trip.origin.inspect}, Destination: #{trip.destination.inspect}"
            trip_planner = TripPlanner.new(trip, options)
            trip_planner.plan

            trip.relevant_purposes = trip_planner.relevant_purposes
            trip.relevant_eligibilities = trip_planner.relevant_eligibilities
            trip.relevant_accommodations = trip_planner.relevant_accommodations
            # trip.disposition_status = Trip::DISPOSITION_STATUSES[:fixed_route_saved] # Not sure if we should update the disposition or not
            trip.disposition_status = Trip::DISPOSITION_STATUSES[:fixed_route_denied] if trip.no_valid_services
            trip.previous_trip = previous_trip
            trip.save!

            previous_trip = trip
          end
        end

        render status: 200, json: @trips.first, include: ['*.*']
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
            # attach itinerary to the trip
            itinerary.select
            results[itinerary.id] = true
            Trip.find(itin["trip_id"]).update(disposition_status: Trip::DISPOSITION_STATUSES[:fixed_route_saved])
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
        # Keep track if anything failed and then cancel all the itineraries ####
        failed = false
        itins  = []
        #########################################################################

        responses = booking_request_params.map do |booking_request|
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
          itins << itin       

          response = booking_response_base(itin).merge({booked: false})
                                        
          # BOOK THE ITINERARY, selecting it and storing the response in a booking object
          if itin.booked?
            # This itinerary has already been booked. Don't book it again.
            next response.merge(booking_response_hash(itin.booking))
          end

          booking_result = itin.try(:book, booking_options: booking_request)
          unless booking_result.is_a?(Booking)
            failed = true
            create_snapshot(itin.trip, booking_result, order: booking_request, eco_trip: nil)
            next response 
          end

          # Ensure that the confirmation is not blank
          if booking_result.confirmation.blank?
            failed = true
            create_snapshot(itin.trip, booking_result, order: booking_request, eco_trip: nil)
            next response 
          end

          create_snapshot(itin.trip, booking_result, order: booking_request, eco_trip: fetch_order(booking_result.confirmation)["order"])
          # Update Trip Disposition Status to ecolane succeeded
          itin.trip.update(disposition_status: Trip::DISPOSITION_STATUSES[:ecolane_booked])
          itin.trip.ecolane_booking_snapshot.update(disposition_status: Trip::DISPOSITION_STATUSES[:ecolane_booked])
          # Package it in a response hash as per API V1 docs
          next response.merge(booking_response_hash(booking_result))
        end

        # If any of the itineraries failed, cancel them all and return failures
        if failed 
          responses = []
          itins.each do |itin|
            itin.booked? ? itin.cancel : itin.unselect

            # Update Trip Disposition Status with ecolane denied if it failed
            itin.trip.update(disposition_status: Trip::DISPOSITION_STATUSES[:ecolane_denied])
            responses << booking_response_base(itin).merge({booked: false})
          end
          render status: 500, json: {booking_results: responses}
        else
          render status: 200, json: {booking_results: responses}
        end
      end

      def create_snapshot(trip, booking, order, eco_trip)
        itinerary = booking.itinerary || trip.itinerary
        user = itinerary&.user
        service = user&.booking_profile&.service
        agency = service&.agency

        new_snapshot = EcolaneBookingSnapshot.new(
          trip_id: trip.id,
          itinerary_id: itinerary&.id,
          status: eco_trip.try(:with_indifferent_access).try(:[], :status),
          confirmation: eco_trip.try(:with_indifferent_access).try(:[], :id),
          details: eco_trip ? eco_trip.to_json : order.to_json,
          earliest_pu: booking.earliest_pu,
          latest_pu: booking.latest_pu,
          negotiated_pu: booking.negotiated_pu,
          negotiated_do: booking.negotiated_do,
          estimated_pu: booking.estimated_pu,
          estimated_do: booking.estimated_do,
          created_in_1click: booking.created_in_1click,
          note: order[:pickup][:note],
          funding_source: booking.details[:funding_hash].try(:[], :funding_source),
          purpose: booking.details[:funding_hash].try(:[], :purpose),
          booking_id: booking.id,
          traveler: user&.email,
          orig_addr: trip.origin.formatted_address,
          orig_lat: trip.origin.lat,
          orig_lng: trip.origin.lng,
          dest_addr: trip.destination.formatted_address,
          dest_lat: trip.destination.lat,
          dest_lng: trip.destination.lng,
          agency_name: agency&.name,
          service_name: service&.name,
          booking_client_id: user&.booking_profile&.external_user_id,
          is_round_trip: trip.previous_trip.present? || trip.next_trip.present?,
          sponsor: booking.details[:funding_hash].try(:[], :sponsor),
          companions: order[:companions].to_i,
          ecolane_error_message: booking.ecolane_error_message,
          pca: order[:assistant],
          disposition_status: trip.disposition_status
        )
        new_snapshot.save!
      end

      # Method does batch updates to round trips
      # - trip details are merged with the current details
      def update_trip_details
        params.permit({details: details_attributes}, :trip)
        params.require(:trip)
        @trips = Trip.where(["id = :trip_id or previous_trip_id = :trip_id", { trip_id: params[:trip] } ])
        if !@trips.empty?
          @trips.each do |trip|
            trip.update(details: trip.details.merge(params[:details]))
          end
          render status:200, json:{trip: @trips}
        else
          render status:404, json: nil
        end
      end

      # POST trips/cancel, itineraries/cancel
      # Unselects and cancels the target itinerary
      def cancel
        success = true 
        results = bookingcancellation_request_params.map do |bc_req|
         
          itin =  @traveler.itineraries.find_by(id: bc_req[:itinerary_id]) ||
                  @traveler.bookings.find_by(confirmation: bc_req[:booking_confirmation]).try(:itinerary)
          trip_type= itin.trip_type
          response = booking_response_base(itin).merge({success: false})

          next response unless itin
          
          # CANCEL THE ITINERARY, unselecting it and updating the booking object
          cancellation_result = itin.booked? ? itin.cancel : itin.unselect

          # This is done to support FMR individual leg cancelling. 
          # If this logic ever changes, ensure that FMR individual leg cancelling is not affected.
          # If this is a round trip, mark any remaining pieces as 1 way
          if cancellation_result
            # Handle the case when the trip is the return trip.
            trip = itin.trip
            trip.previous_trip = nil
            if trip.details
              trip.details[:trip_type]=trip_type
            else
              trip.details = {trip_type: trip_type}
            end
            trip.save 

            # Handle the case when the trip is the outbound trip.
            next_trip = itin.trip.next_trip
            if next_trip
              if next_trip.details
                next_trip.details[:trip_type]=trip_type
              else
                next_trip.details = {trip_type: trip_type}
              end
              next_trip.previous_trip = nil
              next_trip.save
            end

          end

          # Package response as per API V1 docsion
          cancellation_response = bookingcancellation_response_hash(cancellation_result)
          if not cancellation_response[:success] 
            success = false 
          end
          next response.merge(cancellation_response)
        end
        status = (success ? 200 : 406)
        render status: status, json: {cancellation_results: results}
      end

      # Replicates the email functionality from Legacy (Except for the Ecolane Stuff)
      def email
        email_address = params[:email_address]
        booking_confirmations = params[:booking_confirmations]
        trip_id = params[:trip_id]
        if booking_confirmations
          bookings  = @traveler.bookings.where(confirmation: booking_confirmations).order(:earliest_pu)
          decorated_bookings = []
          bookings.each do |booking|
            # GV include calculations to make email look like front end itin
            trip_hash = hash_trip_itinerary(booking.itinerary.trip)
            trip_hash[:trip_id] = trip_id
            # PAMF-633 add same information used to display myrides on front end
            decorated_bookings << {booking: booking, trip_hash: trip_hash}
          end
          UserMailer.ecolane_trip_email([email_address], decorated_bookings).deliver
        else 
          trip = Trip.find(trip_id.to_i)
          UserMailer.user_trip_email([email_address], trip).deliver
        end
        #UserMailer.user_trip_email([email_address], trip).deliver
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
            :mobility_devices,
            :assistant,
            :companions,
            :children,
            :note
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
        if @traveler
          parameters[:trip][:user_id] ||= @traveler.id
        end

        if parameters[:trip][:external_purpose] && @traveler
          parameters[:trip][:purpose_id] ||= Purpose.find_by(name: parameters[:trip][:external_purpose], agency: @traveler.traveler_transit_agency.transportation_agency).id
        end

        parameters[:trip][:details] ||= Trip::DEFAULT_TRIP_DETAILS

        parameters.require(:trip).permit(
          {origin_attributes: place_attributes},
          {destination_attributes: place_attributes},
          {details: details_attributes},
          :trip_time,
          :arrive_by,
          :user_id,
          :purpose_id,
          :external_purpose,
          :note
        )
      end

      def details_attributes
        [:notification_preferences]
      end

      def place_attributes
        [
          :name, :street_number, :route, :city, :state, :zip, :lat, :lng, 
          {
            google_place_attributes: [
              { address_components: [ :long_name, :short_name, {types: []} ] },
              { geometry: [{location: [:lat, :lng]}] }, 
              :name, :formatted_address, :place_id, :original_name
            ]
          }
        ]
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
        trips_hash["1"] = trip_hash(trip.next_trip) if (trip.next_trip and trip.next_trip.selected_itinerary)
        trips_hash
      end
      
      def trip_hash(trip)
        trip_hash = {}
        itin_hash = {}
        service_hash = {}

        # Trip attributes
        trip_hash = {
          trip_id: trip.id,
          details: trip.details,
          origin: WaypointSerializer.new(trip.origin).to_hash,
          destination: WaypointSerializer.new(trip.destination).to_hash
        }

        # Itinerary Attributes
        itin_hash = hash_trip_itinerary(trip)
        service_hash = hash_itinerary_service(trip.selected_itinerary)
        combined_hash = trip_hash.merge(itin_hash).merge(service_hash)
      end

      def hash_trip_itinerary(trip)
        # Trip attributes
        itinerary_hash = {}
        # Itinerary Attributes
        itinerary = trip.selected_itinerary
        if itinerary

          # Calculate Departure
          departure = nil 
          if itinerary.booking 
            if itinerary.booking.estimated_pu
              departure = itinerary.booking.estimated_pu
            elsif itinerary.booking.negotiated_pu
              departure = itinerary.booking.negotiated_pu
            end
          end
          if departure.nil? and itinerary.start_time 
            departure = itinerary.start_time
          end

          # End Time 
          arrival = nil 
          if itinerary.booking 
            if itinerary.booking.estimated_do
              arrival = itinerary.booking.estimated_do
            elsif itinerary.booking.negotiated_do
              arrival = itinerary.booking.negotiated_do
            end
          end
          if arrival.nil?
            arrival = itinerary.end_time
          end

          # Calculate Duration 
          duration = nil 
          if itinerary.booking 
            if itinerary.booking.estimated_do
              duration = itinerary.booking.estimated_do - departure 
            elsif itinerary.booking.negotiated_do
              duration = itinerary.booking.negotiated_do - departure 
            end
          end
          if duration.nil?
            duration = itinerary.duration 
          end

          itinerary_hash = {
            assistant: itinerary.assistant,
            arrival: arrival ? arrival.strftime("%Y-%m-%dT%H:%M") : nil,
            booking_confirmation: itinerary.booking_confirmation,
            comment: nil, # DEPRECATE? in old OneClick, this just takes the English comment
            companions: itinerary.companions,
            cost: itinerary.cost.to_f,
            departure: departure ? departure.strftime("%Y-%m-%dT%H:%M") : nil,
            duration: duration,
            fare: itinerary.cost.to_f,
            id: itinerary.id,
            json_legs: itinerary.legs,
            mode: itinerary.trip_type.nil? ? nil : remodeify(itinerary.trip_type),
            note: itinerary.note,
            product_id: nil, #itinerary.product_id,
            status: itinerary.booking.try(:status) || "ordered", # DEPRECATE?
            transfers: nil, #itinerary.transfers, # DEPRECATE?
            transit_time: itinerary.transit_time,
            wait_time: nil, #itinerary.wait_time, # WAIT TIME?
            walk_distance: nil, #itinerary.walk_distance, # DEPRECATE?
            walk_time: itinerary.walk_time,
            pu_window_start: itinerary.booking ? itinerary.booking.earliest_pu : nil,
            wait_start: itinerary.booking ? itinerary.booking.earliest_pu : nil,
            pu_window_end: itinerary.booking ? itinerary.booking.latest_pu : nil,
            wait_end: itinerary.booking ? itinerary.booking.latest_pu : nil,
            estimated_pickup_time: departure ? departure.strftime("%Y-%m-%dT%H:%M") : nil
          }
        end
        itinerary_hash
      end

      def hash_itinerary_service(itinerary)
        service_hash = {
          service_name: ""
        }
        if itinerary
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
        service_hash
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
            wait_start: (pickup_time - 15.minutes).strftime("%Y-%m-%dT%H:%M"),
            wait_end: (pickup_time + 15.minutes).strftime("%Y-%m-%dT%H:%M"),
            arrival: dropoff_time.strftime("%Y-%m-%dT%H:%M"),
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
            wait_start: booking.earliest_pu,
            wait_end: booking.latest_pu,
            arrival: dropoff_time.strftime("%Y-%m-%dT%H:%M"),
            message: "Booking Status: #{booking.status}",
            negotiated_duration: ((dropoff_time - pickup_time) * 1.day).round # Returns duration in seconds
          }
        when 'ecolane', :ecolane 
          return {
            booked: true,
            confirmation: booking.confirmation, 
            confirmation_id: booking.confirmation, 
            wait_start: booking.negotiated_pu.nil? ? nil : booking.negotiated_pu - 15.minutes,
            wait_end: booking.negotiated_pu.nil? ? nil : booking.negotiated_pu + 15.minutes,
            arrival: booking.negotiated_do,
            message: nil,
            negotiated_duration: (booking.negotiated_pu and booking.negotiated_do) ? (booking.negotiated_do - booking.negotiated_pu) : nil # Returns duration in seconds
          }

        else
          return {}
        end
      end
      
      # Makes an API V1 bookingcancellation response hash from a booking object
      def bookingcancellation_response_hash(booking)
        
        if [true, false].include? booking 
          return {success: booking}
        end

        booking.reload if booking.is_a? Booking
        case booking.try(:type_code)
        when :ride_pilot
          return {
            success: true,
            confirmation_id: booking.confirmation
          }
        when "ecolane"
          return {
            success: booking.status == "canceled"
          }
        else
          return {
            success: true
          }
        end        
      end

      def filter_trip_name(trip)
        # Modify trip names to filter out text after the pipe
        if trip.origin.name.present?
          trip.origin.name = trip.origin.name.split('|').first.strip if trip.origin.name
        else
          trip.origin.name = "#{trip.origin.street_number} #{trip.origin.route}, #{trip.origin.city}".strip
        end

        if trip.destination.name.present?
          trip.destination.name = trip.destination.name.split('|').first.strip if trip.destination.name
        else
          trip.destination.name = "#{trip.destination.street_number} #{trip.destination.route}, #{trip.destination.city}".strip
        end

        # Convert the trip object to hash or any other format as needed
        my_trips_hash(trip)
      end

      private

    end
  end
end
