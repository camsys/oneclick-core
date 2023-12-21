module Api
  module V1
    class PlacesController < ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]
        max_results = (params[:max_results] || 10).to_i

        # Return empty results if search string contains a pipe character
        if search_string.include?('|')
          render status: 200, json: { places_search_results: { locations: [] }, record_count: 0 }
          return
        end

        locations = []

        # Recent Places
        # FMRPA-121 Just skip for now
        if false
          count = 0
          landmarks = authentication_successful? ? @traveler.waypoints.get_by_query_str(search_string).limit(max_results) : []
          landmarks.each do |landmark|
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
        landmarks = Landmark.where("split_part(search_text, '|', 1) ILIKE :search", search: "%#{search_string}%")
                            .where.not(city: [nil, ''])
                            .limit(2 * max_results)

        landmarks = landmarks.where(agency: agencies) if agencies.present?

        names = []
        full_names = []
        landmarks.each do |landmark|
          full_name = landmark.name
          short_name = full_name.split('|').first.strip

          # Skip if the search string matches any part of the name after the first pipe
          next if full_name.split('|', 2)[1]&.include?(search_string)

          # Skip a POI if its full name is already in the list of full names, has no city, or has a bad city
          next if full_names.include?(full_name) || landmark.city.in?(Trip::BAD_CITIES)

          # Create a modified google_place_hash with original_name
          modified_google_place_hash = landmark.google_place_hash
          modified_google_place_hash[:original_name] = full_name

          # Append the modified hash to locations
          locations.append(modified_google_place_hash.merge(name: short_name))

          names << short_name
          full_names << full_name # Add full_name to the list of processed names
          count += 1
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