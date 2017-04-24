module Api
  module V1

    class ItinerarySerializer < ActiveModel::Serializer
      attributes  :accommodation_mismatch,
        :bookable,
        :cost,
        :cost_comments,
        :count,
        :date_mismatch,
        :discounts,
        :duration,
        :duration_estimated,
        :end_location,
        :end_time,
        :external_info,
        :hidden,
        :id,
        :is_bookable,
        :json_legs,
        :legs,
        :logo_url,
        :map_image,
        :match_score,
        :missing_accommodations,
        :missing_information,
        :missing_information_text,
        :mode_id,
        :negotiated_do_time,
        :negotiated_pu_time,
        :negotiated_pu_window_end,
        :negotiated_pu_window_start,
        :order_xml,
        :phone,
        :prebooking_questions,
        :product_id,
        :returned_mode_code,
        :ride_count,
        :schedule,
        :segment_index,
        :selected,
        :server_message,
        :server_status,
        :service_bookable,
        :service_comments,
        :service_id,
        :service_name,
        :start_location,
        :start_time,
        :time_mismatch,
        :too_early,
        :too_late,
        :transfers,
        :transit_time,
        :trip_part_id,
        :trip_type,
        :url,
        :user_registered,
        :wait_time,
        :walk_distance,
        :walk_time


      # FILL IN THESE METHODS AS NEEDED TO MAKE API WORK
      def accommodation_mismatch; false end
      def bookable; false end
      def cost_comments; nil end
      def count; nil end
      def date_mismatch; false end
      def discounts; nil end
      def duration_estimated; true end
      def external_info; nil end
      def hidden; false end
      def is_bookable; false end
      def map_image; nil end
      def match_score; nil end
      def missing_accommodations; "" end
      def missing_information; false end
      def missing_information_text; nil end
      def negotiated_pu_time; nil end
      def negotiated_do_time; nil end
      def negotiated_pu_window_start; nil end
      def negotiated_pu_window_end; nil end
      def order_xml; nil end
      def prebooking_questions; [] end
      def ride_count; nil end
      def schedule; [] end
      def segment_index; 0 end
      def selected; nil end
      def server_message; nil end
      def server_status; 200 end
      def service_bookable; false end
      def time_mismatch; false end
      def too_early; false end
      def too_late; false end
      def transfers; nil end
      def trip_part_id; nil end
      def user_registered; false end
      def wait_time; 0 end
      def walk_distance; nil end


      # ACTUAL METHODS

      def product_id
        object.uber_extension ? object.uber_extension.product_id : nil
      end

      def end_location
        return nil unless object.trip
        location_hash(object.trip.destination)
      end

      def start_location
        return nil unless object.trip
        location_hash(object.trip.origin)
      end

      def json_legs
        object.legs
      end

      # Update to pull from Itinerary trip_type child class?
      def mode_id
        (object.legs.nil? || object.legs.empty?) ? 2 : 1
      end

      def returned_mode_code
        object.trip_type.nil? ? nil : "mode_#{object.trip_type.to_s}"
      end

      # Service fields
      def service_name
        object.service && object.service.name
      end

      def phone
        object.service && object.service.phone
      end

      def url
        object.service && object.service.url
      end

      def service_comments
        return {} unless object.service
        Hash[object.service.comments.map {|c| [c.locale, c.comment]}]
      end

      def logo_url
        return nil unless object.service && object.service.logo
        object.service.full_logo_url
      end

      private

      def location_hash(waypoint)
        {
          geometry: {
            location: {
              lat: waypoint.lat,
              lng: waypoint.lng
            }
          }
        }
      end

    end

  end
end
