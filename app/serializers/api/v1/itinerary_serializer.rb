module Api
  module V1

    class ItinerarySerializer < ActiveModel::Serializer

      include ScheduleHelper

      attributes :cost,
        # :accommodation_mismatch,    # DEPRECATE?
        # :bookable,                  # DEPRECATE?
        # :cost_comments,             # DEPRECATE?
        # :count,                     # DEPRECATE?
        # :date_mismatch,             # DEPRECATE?
        :discounts,                 # BOOKING
        :duration,
        # :duration_estimated,        # DEPRECATE?
        :end_location,
        :end_time,
        # :external_info,             # DEPRECATE?
        # :hidden,                    # DEPRECATE? possibly used
        :id,
        #:is_bookable,               # DEPRECATE?
        :json_legs,
        # :legs,                      # front end uses json_legs
        :logo_url,
        # :map_image,                 # DEPRECATE?
        # :match_score,               # DEPRECATE?
        # :missing_accommodations,    # DEPRECATE?
        # :missing_information,       # DEPRECATE?
        # :missing_information_text,  # DEPRECATE?
        # :mode_id,                   # DEPRECATE?
        # :negotiated_do_time,        # DEPRECATE?
        # :negotiated_pu_time,        # DEPRECATE?
        # :negotiated_pu_window_end,  # DEPRECATE?
        # :negotiated_pu_window_start,# DEPRECATE?
        # :order_xml,                 # DEPRECATE?
        :phone,
        :prebooking_questions,      # BOOKING
        :product_id,
        :returned_mode_code,
        # :ride_count,                # DEPRECATE?
        :schedule,
        :segment_index,
        # :selected,                  # DEPRECATE?
        # :server_message,            # DEPRECATE?
        # :server_status,             # DEPRECATE?
        :service_bookable,          # BOOKING
        :service_comments,
        :service_id,
        :service_name,
        :start_location,
        :start_time,
        # :time_mismatch,             # DEPRECATE?
        # :too_early,                 # DEPRECATE?
        # :too_late,                  # DEPRECATE?
        # :transfers,                 # DEPRECATE?
        # :transit_time,              # not needed in call
        # :trip_part_id,              # DEPRECATE?
        # :trip_type,                 # front end uses returned_mode_code?
        :url,                         # should be called service_url probably, or really nested in a service object
        :user_registered,           # BOOKING
        :wait_time,                 # not needed in call
        :walk_distance,
        :walk_time


      # STUB METHODS FOR DEPRECATED ATTRIBUTES
      # def accommodation_mismatch; false end
      def bookable; false end
      # def cost_comments; nil end
      # def count; nil end
      # def date_mismatch; false end
      # def discounts; nil end
      # def duration_estimated; true end
      # def external_info; nil end
      # def hidden; false end
      # def is_bookable; false end
      # def map_image; nil end
      # def match_score; nil end
      # def missing_accommodations; "" end
      # def missing_information; false end
      # def missing_information_text; nil end
      # def mode_id; nil end
      # def negotiated_pu_time; nil end
      # def negotiated_do_time; nil end
      # def negotiated_pu_window_start; nil end
      # def negotiated_pu_window_end; nil end
      # def order_xml; nil end
      # def prebooking_questions; [] end
      def product_id; nil end
      # def ride_count; nil end
      # def schedule; [] end
      # def selected; nil end
      # def server_message; nil end
      # def server_status; 200 end
      # def service_bookable; false end
      # def time_mismatch; false end
      # def too_early; false end
      # def too_late; false end
      # def transfers; nil end
      # def trip_part_id; nil end
      # def user_registered; false end
      # def wait_time; 0 end
      # def walk_distance; nil end


      # ACTUAL METHODS

      def segment_index 
        if object.trip.previous_trip
          return 1
        else
          return 0
        end
      end

      def product_id
        object.uber_extension ? object.uber_extension.product_id : nil
      end

      def end_location
        return nil unless object.trip
        location_hash(object.trip.destination)
      end

      def end_time
        object.end_time && object.end_time.iso8601
      end

      def json_legs
        augmented_legs
      end

      def logo_url
        return nil unless object.service && object.service.logo
        object.service.full_logo_url
      end

      def phone
        object.service && object.service.formatted_phone
      end

      def returned_mode_code
        if object.trip_type == "uber" 
          return "mode_ride_hailing"
        end
        object.trip_type.nil? ? nil : "mode_#{object.trip_type.to_s}"
      end

      def schedule
        return full_schedule unless object.try(:service).try(:schedules).try(:for_display).present?
        object.service.schedules.for_display.order(:day).map do |sched|
          end_time_not_midnight = sched.end_time == ScheduleHelper::DAY_LENGTH ? sched.end_time - 1 : sched.end_time
          {
            day: Date::DAYNAMES[sched.day],
            start: [schedule_time_to_string(sched.start_time)],
            end: [schedule_time_to_string(end_time_not_midnight)]
          }
        end
      end

      def service_comments
        return {} unless object.service
        I18n.available_locales
            .map {|l| [l, object.service.description(l)] }
            .to_h
      end

      def service_id
        object.service && object.service.id
      end

      def service_name
        object.service && object.service.name
      end

      def start_location
        return nil unless object.trip
        location_hash(object.trip.origin)
      end

      def start_time
        object.start_time && object.start_time.iso8601
      end

      def url
        object.service && object.service.url
      end

      ### BOOKING ###
      def service_bookable
        object.service.try(:bookable?)
      end
      
      def user_registered
        object.user.try(:has_booking_profile_for?, object.service)
      end
      
      def discounts
        if object.bookable? and not object.user.try(:registered?)
          return object.booking_ambassador.discounts_hash
        else
          return nil
        end
      end
      
      def prebooking_questions
        object.booking_ambassador.try(:prebooking_questions)
      end
      

      private

      def augmented_legs
        if object.legs?
          object.legs.each do |leg|
            if leg['agencyId']
              service = Service.find_by(gtfs_agency_id: leg['agencyId'])
              if service and service.fare_structure == "url"
                leg["serviceFareInfo"] = service.fare_details[:url] 
              end
            end
          end
        end
        object.legs
      end

      def location_hash(waypoint)
        {
          geometry: {
            location: {
              lat: waypoint.lat.to_f,
              lng: waypoint.lng.to_f
            }
          },
          formatted_address: waypoint.formatted_address,
          id: object.id,
          name: waypoint.name,
          stop_code: nil,
          address_components: waypoint.address_components
        }
      end
      
      def full_schedule
        (0..6).map do |d|
          {
            day: Date::DAYNAMES[d],
            start: [schedule_time_to_string(0)],
            end: [schedule_time_to_string(ScheduleHelper::DAY_LENGTH - 1)]
          }
        end
      end

    end

  end
end
