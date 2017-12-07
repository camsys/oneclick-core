module Api
  module V2
    class PlacesController < ApiController
      
      before_action :ensure_traveler
      
      def index
        search_string = "%#{params[:name]}%" # Pad the query string with %s to get all matching strings

        limit = params[:max_results] || 5
        results= []
        
        # Get Matching Stomping Grounds
        results += @traveler.stomping_grounds.get_by_query_str(search_string).limit(limit)
        
        # Get Matching Landmarks
        results += Landmark.get_by_query_str(search_string).limit(limit)
          
        # Placeholder for get matching recent waypoints
        # Combine exact matches with approximate matches, then take unique results by name/lat/lng and limit
        recent_waypoints = (
          @traveler.recent_waypoints.where(name: params[:name]) + 
          @traveler.recent_waypoints.get_by_query_str(search_string)
        )
        .take(limit)
        
        results += recent_waypoints
        
        render(success_response(results, root: "places", serializer: Api::GooglePlaceSerializer))
      end
      
    end
  end
end
