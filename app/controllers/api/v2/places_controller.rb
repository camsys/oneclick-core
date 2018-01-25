module Api
  module V2
    class PlacesController < ApiController
      
      def index
        search_string = "%#{params[:name]}%" # Pad the query string with %s to get all matching strings

        limit = params[:max_results] || 5
        results= []
        
        # Get Matching Stomping Grounds
        results += @traveler.stomping_grounds
                            .get_by_query_str(search_string)
                            .limit(limit) if @traveler
        
        # Get Matching Landmarks
        # Don't do this if the search is blank. 
        # A blank search is used to show ALL recent waypoints and ALL stomping grounds
        unless params[:name].blank? 
          results += Landmark.get_by_query_str(search_string)
                             .limit(limit)
        end
          
        # Get Matching Recent Waypoints
        # exact matches
        results += @traveler.waypoints
                            .where(name: params[:name])
                            .order(created_at: :desc)
                            .limit(limit) if @traveler
        # substring matches
        results += @traveler.waypoints
                            .get_by_query_str(search_string)
                            .order(created_at: :desc)
                            .limit(limit) if @traveler
        
        # Filter out any duplicate results that remain
        results.uniq! { |p| [p.name, p.lat, p.lng] }
        
        render(success_response(results, root: "places", serializer: Api::GooglePlaceSerializer))
      end
      
    end
  end
end
