module Api
  module V2
    class TravelPatternsController < ApiController
      before_action :require_authentication

      def index
        user_county = traveler.return_county_if_ecolane_email.name

        agency = @traveler.traveler_transit_agency.transportation_agency
        services = Service.where(agency_id: agency.id).paratransit_services.published.is_ecolane
        services = services.filter { |service|
          counties = service.booking_details[:home_counties].split(',').map(&:strip)
          counties.include? (user_county)
        }
        
        Rails.logger.info("Filtering through Travel Patterns with agency_id: #{agency.id}")
        travel_pattern_query = TravelPattern.where(agency: agency)
        travel_pattern_query = TravelPattern.filter_by_service(travel_pattern_query, services)
        travel_pattern_query = TravelPattern.filter_by_origin(travel_pattern_query, query_params[:origin])
        travel_pattern_query = TravelPattern.filter_by_destination(travel_pattern_query, query_params[:destination])
        travel_pattern_query = TravelPattern.filter_by_purpose(travel_pattern_query, query_params[:purpose])
        travel_pattern_query = TravelPattern.filter_by_funding_sources(travel_pattern_query, query_params[:purpose], @traveler&.booking_profile&.booking_ambassador)
        travel_pattern_query = TravelPattern.filter_by_date(travel_pattern_query, query_params[:date])
        travel_patterns = TravelPattern.filter_by_time(travel_pattern_query, query_params[:start_time], query_params[:end_time])

        # Finally, filter out any patterns with no bookable dates. This can happen prior to selecting a date and time
        # if a travel pattern has only calendar date schedules and the dates are outside of the booking window.
        travel_patterns = travel_patterns.map(&:to_api_response)
        travel_patterns.select! { |travel_pattern|
          dates = travel_pattern['to_calendar'].values
          dates.detect { |date|
            (date[:start_time] || -1) >= 0 && (date[:start_time] || -1) >= 1
          }
        }

        if travel_patterns.any?
          Rails.logger.info("Found the following matching Travel Patterns: #{ travel_patterns.map{|t| t['id']} }")
          render status: :ok, json: { 
            status: "success", 
            data: travel_patterns
          }
        else
          Rails.logger.info("No matching Travel Patterns found")
          render fail_response(status: 404, message: "Not found")
        end
      end
      
      protected

      def query_params
        @query ||= params.permit(
          :purpose,
          :date,
          :start_time,
          :end_time,
          origin: [:lat, :lng],
          destination: [:lat, :lng]
        )
      end

    end
  end
end
