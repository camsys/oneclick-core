module Api
  module V1
    class PlacesController < ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]
        max_results = (params[:max_results] || 10).to_i

        locations = []

        # Recent Places
        # FMRPA-121 Just skip for now
        if false
          count = 0
          landmarks = authentication_successful? ? @traveler.waypoints.get_by_query_str(search_string).limit(max_results) : []
          landmarks.each do |landmark|
            full_name = landmark.name
            short_name = full_name.split('|').first.strip
            session[short_name] = full_name # Store the full name in the session
            # Skip returning a Place if it doesn't have a city or if it has a bad city
            # - this helps prevent users from selecting a city-less Place
            # ...and booking shared ride trips with it(it shows up in Ecolane with no city)
            if !landmark.city.nil? && landmark.city != '' && !landmark.city.in?(Trip::BAD_CITIES)
              locations.append(landmark.google_place_hash)
              count += 1
              if count >= max_results
                break
              end
            else
              next
            end
          end
        end

        # Global POIs
        count = 0
        # Filter by agencies associated with user's services
        agencies = authentication_successful? ? @traveler.booking_profiles.collect(&:service).compact.collect(&:agency) : []

        # Return extras as some may be filtered out later
        # landmarks = Landmark.where("name ILIKE :search", search: "%#{search_string}%").where.not(city: [nil, ''])
        #              .limit(2 * max_results)
        landmarks = Landmark.where("search_text ILIKE :search", search: "%#{search_string}%").where.not(city: [nil, ''])
                            .limit(2 * max_results)

        landmarks = landmarks.where(agency: agencies) if agencies.present?

        FULL_NAMES_MAPPING = {}
        landmarks.each do |landmark|
          key = [landmark.lat, landmark.lng].join(':')
        
          FULL_NAMES_MAPPING[key] = landmark.name
        
          short_name = landmark.name.split('|').first.strip
        
          if !short_name.in?(names) && !landmark.city.in?(Trip::BAD_CITIES)
            locations.append(landmark.google_place_hash.merge(name: short_name))
            names << short_name
            count += 1
          end
        
          break if count >= max_results
        end

        # User StompingGrounds
        # FMRPA-121 Just skip for now
        if false
          count = 0
          landmarks = authentication_successful? ? @traveler.stomping_grounds.limit(20).get_by_query_str(search_string).limit(max_results) : []
          names = []
          landmarks.each do |landmark|
            unless landmark.name.in? names 
              locations.append(landmark.google_place_hash)
              names << landmark.name
              count += 1
            end
            if count >= max_results
              break
            end
          end
        end
        
        hash = {places_search_results: {locations: locations}, record_count: locations.count}
        render status: 200, json: hash

      end

      def recent
        count = params[:count] || 20
        recent_places = authentication_successful? ? @traveler.recent_waypoints(count) : []
        render status: 200, json: {places: WaypointSerializer.collection_serialize(recent_places) }
      end

      # STUBBED method for communication with UI
      def within_area
        render status: 200, json: {result: true}
      end

    end
  end
end
