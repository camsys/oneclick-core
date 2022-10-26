module Api
  module V2
    class TravelPatternsController < ApiController
      before_action :require_authentication

      def index
        agency = @traveler.traveler_transit_agency.transportation_agency
        travel_pattern_query = TravelPattern.where(agency: agency)
        Rails.logger.info("Filtering through Travel Patterns with agency_id: #{agency.id}")

        travel_pattern_query = filter_by_origin(travel_pattern_query, query_params[:origin])
        travel_pattern_query = filter_by_destination(travel_pattern_query, query_params[:destination])
        travel_pattern_query = filter_by_purpose(travel_pattern_query, query_params[:purpose])
        travel_pattern_query = filter_by_funding_sources(travel_pattern_query, query_params[:purpose])
        travel_pattern_query = filter_by_date(travel_pattern_query, query_params[:date])
        travel_patterns = filter_by_time(travel_pattern_query, query_params[:start_time], query_params[:end_time])

        if travel_patterns.any?
          Rails.logger.info("Found the following matching Travel Patterns: #{travel_patterns.map(&:id)}")
          render status: :ok, json: { 
            status: "success", 
            data: travel_patterns.map(&:to_api_response)
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

      def filter_by_origin(travel_pattern_query, origin)
        return travel_pattern_query unless origin.present? && origin[:lat].present? && origin[:lng].present?

        travel_patterns = TravelPattern.arel_table
        origin_zone_ids = OdZone.joins(:region).merge(Region.containing_point(origin[:lng], origin[:lat])).pluck(:id)

        travel_pattern_query.where(
          travel_patterns[:origin_zone_id].in(origin_zone_ids).or(
            travel_patterns[:destination_zone_id].in(origin_zone_ids).and(
              travel_patterns[:allow_reverse_sequence_trips].eq(true)
            )
          )
        )
      end

      def filter_by_destination(travel_pattern_query, destination)
         return travel_pattern_query unless destination.present? && destination[:lat].present? && destination[:lng].present?

         travel_patterns = TravelPattern.arel_table
         destination_zone_ids = OdZone.joins(:region).merge(Region.containing_point(destination[:lng], destination[:lat])).pluck(:id)

         travel_pattern_query.where(
           travel_patterns[:destination_zone_id].in(destination_zone_ids).or(
             travel_patterns[:origin_zone_id].in(destination_zone_ids).and(
               travel_patterns[:allow_reverse_sequence_trips].eq(true)
             )
           )
         )
      end

      def filter_by_purpose(travel_pattern_query, purpose)
        return travel_pattern_query unless purpose.present?
  
        Rails.logger.info("Filtering through Travel Patterns that have the Purpose: #{purpose}")
        travel_pattern_query.joins(:purposes)
                            .merge(Purpose.where(name: purpose))
      end

      def filter_by_funding_sources(travel_pattern_query, purpose)
        return travel_pattern_query unless purpose.present?

        valid_funding_sources = []
        get_funding = true
        customer_info = @traveler.booking_profile.booking_ambassador.fetch_customer_information(get_funding)
        funding_sources = [customer_info['customer']['funding']['funding_source']].flatten

        funding_sources.each do |funding_source|
          allowed = [funding_source['allowed']].flatten
          if allowed.detect { |hash| hash['purpose'] == purpose }
            valid_funding_sources.push(funding_source['name'])
          end
        end

        Rails.logger.info("Filtering through Travel Patterns that have at least one of these funding sources: #{valid_funding_sources}")
        travel_pattern_query.joins(:funding_sources)
                            .merge(FundingSource.where(name: valid_funding_sources))
      end

      def filter_by_date(travel_pattern_query, trip_date)
        return travel_pattern_query unless trip_date.present?

        Rails.logger.info("Filtering through Travel Patterns that have a Service Schedule running on: #{trip_date}")
        Rails.logger.info("Filtering through Travel Patterns that have a Booking Window that includes: #{trip_date}")
        trip_date = Date.strptime(trip_date, '%Y-%m-%d')
        travel_pattern_query.for_date(trip_date)
      end

      # This method should be the first time we call the database, before this we were only constructing the query
      def filter_by_time(travel_pattern_query, trip_start, trip_end)
        return travel_pattern_query unless trip_start
        trip_start = trip_start.to_i
        trip_end = (trip_end || trip_start).to_i
        
        Rails.logger.info("Filtering through Travel Patterns that have a Service Schedule running from: #{trip_start/1.hour}:#{trip_start%1.minute}, to: #{trip_end/1.hour}:#{trip_end%1.minute}")
        # Eager loading will ensure that all the previous filters will still apply to the nested relations
        travel_patterns = travel_pattern_query.eager_load(travel_pattern_service_schedules: {service_schedule: [:service_schedule_type, :service_sub_schedules]})
        travel_patterns.select do |travel_pattern|
          schedules = travel_pattern.schedules_by_type

          # If there are reduced schedules, then we don't need to check any other schedules
          if schedules[:reduced_service_schedules].present?
            Rails.logger.info("Travel Pattern ##{travel_pattern.id} has matching reduced service schedules")
            schedules = schedules[:reduced_service_schedules]
          else
            Rails.logger.info("Travel Pattern ##{travel_pattern.id} does not have maching calendar date schedules, checking other schedule types")
            schedules = schedules[:reduced_service_schedules] + schedules[:extra_service_schedules]
          end

          # Grab any valid schedules
          schedules.any? do |travel_pattern_service_schedule|
            service_schedule = travel_pattern_service_schedule.service_schedule
            service_schedule.service_sub_schedules.any? do |sub_schedule|
              valid_start_time = sub_schedule.start_time <= trip_start
              valid_end_time = sub_schedule.end_time >= trip_end

              valid_start_time && valid_end_time
            end
          end 
        end # end travel_patterns.select
      end # end filter_by_time
    end
  end
end
