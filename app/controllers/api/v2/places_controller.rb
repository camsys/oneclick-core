module Api
  module V2
    class PlacesController < ApiController
      
      before_action :ensure_traveler
      
      def index
        search_string = "%#{params[:name]}%" # Pad the query string with %s to get all matching strings

        limit = params[:max_results] || 5
        results= []
        
        if @traveler
          # Get Matching Stomping Grounds
          results += StompingGround.get_by_query_str(search_string, limit, @traveler)
          
          # Placeholder for get matching recent waypoints
        end

        # Get Matching Landmarks
        landmarks = Landmark.get_by_query_str(search_string, limit)
        results += landmarks
        
        render(success_response(results, root: "places", serializer: Api::GooglePlaceSerializer))
      end
    end
  end
end
