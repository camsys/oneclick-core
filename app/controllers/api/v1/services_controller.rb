module Api
  module V1
    class ServicesController < ApiController

      # FOR ECOLANEs
      def ids_humanized
        external_id_array = []
        Service.paratransit_services.published.is_ecolane.each do |service|
          external_id_array += service.booking_details[:home_counties].split(',').map{ |x| x.strip }
        end
        external_id_array.map(&:humanize).uniq.sort
        render status: 200, json: {service_ids: external_id_array}
      end

      # For Ecolane
      #Given a registered traveler.  Return the dates/hours that are allowed for booking
      def hours

        today = Date.today
        hours = {}

        #if @traveler.is_visitor? or @traveler.is_api_guest? #Return a wide range of hours
        if not @user.registered?
          (0..21).each do |n|
            hours[(today + n).to_s] = {open: "07:00", close: "22:00"}
          end

        else # This is not a guest, check to see if the traveler is registered with a service

          if @user.booking_profiles.count > 0 #This user is registered with a service
            booking_profile = @user.booking_profiles.first
            service = booking_profile.service

            min_notice_days = 2#(service.advanced_notice_minutes || 1440).to_i / 1440 #Minimum notice in days
            max_notice_days = 14#[(service.max_advanced_book_minutes || 20160).to_i / 1440, 28].min #Max advanced notice (up to 28 days)

            if false#user_service.unrestricted_hours #This user is allowed to book at all times
              (1..21).each do |n|
                hours[(today + n).to_s] = {open: "00:00", close: "23:59"}
              end
            elsif service.schedules.count > 0 #This user's service has listed hours

              (min_notice_days..max_notice_days).each do |n|
                schedule = service.schedules.where(day: (today + n).wday).first
                if schedule
                  hours[(today + n).to_s] = {start_time: schedule.schedule_time_to_string(schedule.start_time), 
                    end_time: schedule.schedule_time_to_string(schedule.end_time)}
                end
              end

            else #This user is registered with a service, but that service has not entered any hours

              (min_notice_days..max_notice_days).each do |n|
                unless (today + n).saturday? or (today + n).sunday?
                  hours[(today + n).to_s] = {open: "08:00", close: "17:00"}
                end
              end

            end

          else #This user is logged in but isn't registered with a service

            (1..14).each do |n|
              unless (today + n).saturday? or (today + n).sunday?
                hours[(today + n).to_s] = {open: "08:00", close: "17:00"}
              end
            end

          end # if #traveler.user_profile.user_services.count > 0
        end # if @travler.is_visitor

        respond_with hours

      end #hours

    end
  end
end
