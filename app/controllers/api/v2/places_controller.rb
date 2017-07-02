module Api
  module V2
    class PlacesController < ApiController

      def index
        search_string = params[:name]
        limit = params[:max_results] || 5
        results= []
        
        if @traveler
          # Get Matching Stomping Grounds
          stomping_grounds = StompingGround.get_by_query_str(search_string, limit, @traveler)
          stomping_grounds.each do |stomping_ground|
            results.append(stomping_ground.google_place_hash)
          end
          # Placeholder for get matching recent waypoints
        end

        # Get Matching Landmarks
        landmarks = Landmark.get_by_query_str(search_string, limit)
        landmarks.each do |landmark|
          results.append(landmark.google_place_hash)
        end
        render(success_response(results))
      end
    end
  end
end