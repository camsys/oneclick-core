module Api
  module V1
    class PlacesController < ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]
        max_results = (params[:max_results] || 5).to_i

        #If the search string is empty, just return the recent places for the user.
        if search_string.blank?
          count = params[:count] || 20
          recent_places = authentication_successful? ? @traveler.recent_waypoints(count) : []
          render status: 200, json: {places: WaypointSerializer.collection_serialize(recent_places) }
          return
        end

        locations = []

        # Global POIs
        count = 0
        landmarks = Landmark.get_by_query_str(search_string).limit(max_results)
        landmarks.each do |landmark|
          locations.append(landmark.google_place_hash)
          count += 1
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
