module Api
  module V2
    class TravelPatternsController < ApiController
      before_action :require_authentication

      def index
        agency = @traveler.traveler_transit_agency.transportation_agency
        travel_pattern_query = TravelPattern.where(agency: agency)
        Rails.logger.info("Filtering through Travel Patterns with agency_id: #{agency.id}")

        # TODO
        # travel_pattern_query = filter_by_origin(travel_pattern_query, query_params[:origin])
        # travel_pattern_query = filter_by_destination(travel_pattern_query, query_params[:destination])
        travel_pattern_query = filter_by_purpose(travel_pattern_query, query_params[:purpose_id])
        travel_pattern_query = filter_by_date(travel_pattern_query, query_params[:date])
        travel_patterns = filter_by_time(travel_pattern_query, query_params[:start_time], query_params[:duration])

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
        @query ||= params.fetch(:travel_pattern, {}).permit(
          :origin,
          :destination,
          :purpose_id,
          :date,
          :start_time,
          :duration
        )
      end

      # TODO
      # def filter_by_origin(travel_pattern_query, origin)
      #   return travel_pattern_query unless origin.present?

      #   travel_patterns = TravelPattern.arel_table
      #   origin_zone_ids = OdZone.joins(:region).merge(Region.containing(origin)).pluck(:id)

      #   travel_pattern_query.where(
      #     travel_patterns[:origin_zone_id].in(origin_zone_ids).or(
      #       travel_patterns[:destination_zone_id].in(origin_zone_ids).and(
      #         travel_patterns[:allow_reverse_sequence_trips].eq(true)
      #       )
      #     )
      #   )
      # end

      # TODO
      # def filter_by_destination(travel_pattern_query, destination)
      #   return travel_pattern_query unless destination.present?

      #   travel_patterns = TravelPattern.arel_table
      #   destination_zone_ids = OdZone.joins(:region).merge(Region.containing(destination)).pluck(:id)

      #   travel_pattern_query.where(
      #     travel_patterns[:destination_zone_id].in(destination_zone_ids).or(
      #       travel_patterns[:origin_zone_id].in(destination_zone_ids).and(
      #         travel_patterns[:allow_reverse_sequence_trips].eq(true)
      #       )
      #     )
      #   )
      # end

      def filter_by_purpose(travel_pattern_query, purpose_id)
        return travel_pattern_query unless purpose_id.present?

        Rails.logger.info("Filtering through Travel Patterns that have a Purpose with id: #{purpose_id}")
        travel_pattern_query.joins(:travel_pattern_purposes)
                            .merge(TravelPatternPurpose.where(purpose_id: purpose_id))
      end

      def filter_by_date(travel_pattern_query, trip_date)
        return travel_pattern_query unless trip_date.present?

        Rails.logger.info("Filtering through Travel Patterns that have a Service Schedule running on: #{trip_date}")
        Rails.logger.info("Filtering through Travel Patterns that have a Booking Window that includes: #{trip_date}")
        trip_date = Date.strptime(trip_date, '%Y-%m-%d')
        travel_pattern_query.for_date(trip_date)
      end

      # This method should be the first time we call the database, before this we were only constructing the query
      def filter_by_time(travel_pattern_query, trip_start, trip_duration)
        return travel_pattern_query unless trip_start
        trip_start = trip_start.to_i
        trip_duration = trip_duration.to_i
        trip_end = trip_start + trip_duration

        Rails.logger.info("Filtering through Travel Patterns that have a Service Schedule running from: #{trip_start/1.hour}:#{trip_start%1.minute}, to: #{trip_end/1.hour}:#{trip_end%1.minute}")
        # Eager loading will ensure that all the previous filters will still apply to the nested relations
        travel_patterns = travel_pattern_query.eager_load(service_schedules: [:service_schedule_type, :service_sub_schedules])
        travel_patterns.select do |travel_pattern|
          # Check for calendar date schedules first
          schedules = travel_pattern.service_schedules.select do |service_schedule|
            service_schedule.service_schedule_type.name == 'Selected calendar dates'
          end

          # If there are calendar date schedules, then we don't need to check weekly schedules
          if schedules.present?
            Rails.logger.info("Travel Pattern ##{travel_pattern.id} has matching calendar date schedules")
          else
            Rails.logger.info("Travel Pattern ##{travel_pattern.id} does not have maching calendar date schedules, defaulting to weekly schedules")
            schedules = travel_pattern.service_schedules unless schedules.present?
          end

          # Grab any valid schedules
          schedules.any? do |service_schedule|
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
