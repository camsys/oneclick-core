module Api
  module V2
    class TravelPatternsController < ApiController
      before_action :require_authentication

      def index
        agency = @traveler.transportation_agency
        service = @traveler.current_service
        purpose = query_params.delete(:purpose)
        funding_source_names = @traveler.get_funding_data(service)[purpose]
        date = query_params.delete(:date)

        query_params[:agency] = agency
        query_params[:service] = service
        query_params[:purpose] = Purpose.find_or_initialize_by(agency: agency, name: purpose.strip) if purpose
        query_params[:funding_sources] = FundingSource.where(name: funding_source_names) if purpose # check funding sources only if there's also a trip purpose
        query_params[:date] = Date.strptime(query_params[:date], '%Y-%m-%d') if date

        Rails.logger.info("Filtering through Travel Patterns with the following filters: #{query_params}")
        travel_patterns = TravelPattern.available_for(query_params)

        if travel_patterns.any?
          travel_pattern_ids = travel_patterns.map { |t| t['id'] } # Get travel pattern IDs
          Rails.logger.info("Found the following matching Travel Patterns: #{travel_pattern_ids}")

          valid_from, valid_until = nil, nil # Initialize valid_from and valid_until to avoid errors

          # Call to_api_response and pass service along with dates
          api_response = travel_patterns.map do |pattern|
            TravelPattern.to_api_response(pattern, service, valid_from, valid_until)
          end

          # Fetch purposes only if there is a booking_profile
          booking_profile = @traveler.booking_profiles.first
          if booking_profile
            begin
              Rails.logger.info("Passing travel_pattern_ids to ambassador: #{travel_pattern_ids}")
              trip_purposes, trip_purposes_hash = booking_profile.booking_ambassador.get_trip_purposes(travel_pattern_ids)
            rescue Exception => e
              Rails.logger.error("Error fetching trip purposes: #{e.message}")
              trip_purposes = []
              trip_purposes_hash = []
            end
          end

          render status: :ok, json: { status: "success", data: api_response }
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
