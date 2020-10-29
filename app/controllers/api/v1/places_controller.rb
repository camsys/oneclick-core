module Api
  module V1
    class PlacesController < ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]
        max_results = (params[:max_results] || 5).to_i

        locations = []

        #If the search string is empty, just return the recent places for the user.
        if search_string == "% %"
          recent_places = authentication_successful? ? @traveler.recent_waypoints(3*max_results) : []
          recent_places.each do |landmark|
            landmark_hash = landmark.google_place_hash
            ["id"].each do |key|
              landmark_hash.delete(key)
            end
            if (landmark_hash["name"] || "").in? landmark_hash["formatted_address"]
              landmark_hash["name"] =  ""
            end
            locations.append(landmark_hash)
            locations.uniq!
            if locations.count >= max_results
              break
            end
          end
          hash = {places_search_results: {locations: locations}, record_count: locations.count}
          render status: 200, json: hash
          return 
        end

        # Recent Places
        count = 0
        landmarks = authentication_successful? ? @traveler.waypoints.get_by_query_str(search_string).limit(max_results) : []
        landmarks.each do |landmark|
          locations.append(landmark.google_place_hash)
          count += 1
          if count >= max_results
            break
          end
        end


        # Global POIs
        count = 0
        landmarks = Landmark.get_by_query_str(search_string).limit(max_results)
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

        # User StompingGrounds
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
