module Api
  module V2
    class PlacesController < ApiController

      def index
        search_string = params[:search]
        max_results = params[:max_results] || 5
        results= []
        
        # Get Matching Landmarks
        landmarks = Landmark.get_by_query_str(search_string, max_results)
        landmarks.each do |landmark|
          results.append(landmark.google_place_hash)
        end

        # Get Matching Stomping Grounds
        #render status: 200, json: results

        # Placeholder for get matching recent waypoints

        render(success_response(results))
      end
    end
  end
end