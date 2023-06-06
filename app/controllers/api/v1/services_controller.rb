module Api
  module V1
    class ServicesController < ApiController

      # FOR ECOLANEs
      def ids_humanized
        external_array = []
        Service.paratransit_services.published.with_ecolane_api.each do |service|
          county_services = service.booking_details[:home_counties]
                                    .split(',')
                                    .map{ |county_name| 
                                      {
                                        serviceId: service.id,
                                        label: "#{county_name.strip.humanize} - #{service.name}",
                                        countyName: county_name.strip.humanize
                                      }
                                    }
          external_array += county_services
        end
        render status: 200, json: {
          county_services: external_array,
          service_ids: external_array.map{ |county_service|
            county_service[:countyName]
          }
        }

        # external_id_array = []
        # Service.paratransit_services.published.with_ecolane_api.each do |service|
        #   external_id_array += service.booking_details[:home_counties].split(',').map{ |x| x.strip }
        # end
        # render status: 200, json: {service_ids: external_id_array.map(&:humanize).uniq.sort}
      end

      # For Ecolane
      #Given a registered traveler.  Return the dates/hours that are allowed for booking
      def hours

        today = Date.today
        hours = {}
        #if @traveler.is_visitor? or @traveler.is_api_guest? #Return a wide range of hours
        if not @traveler or not @traveler.registered?
          (0..30).each do |n|
            hours[(today + n).to_s] = {open: "07:00", close: "22:00"}
          end

        else # This is not a guest, check to see if the traveler is registered with a service

          # NOTE(wilsonj806) For now this implementation does not let registered users
          #...book trips on weekends. Eventually we want to change that so they can do so

          if @traveler.booking_profiles.count > 0 #This user is registered with a service
            booking_profile = @traveler.booking_profiles.first
            service = booking_profile.service

            min_notice_days = (service.booking_details[:min_days] || 2).to_i
            max_notice_days = (service.booking_details[:max_days] || 14).to_i

            
            if service.booking_details[:trusted_users] and booking_profile.external_user_id.in? service.booking_details.try(:[], :trusted_users).split(',').map{ |x| x.strip }
              (1..21).each do |n|
                hours[(today + n).to_s] = {open: "00:00", close: "23:59"}
              end
            elsif service.schedules.count > 0 #This user's service has listed hours. This is the most common case.
              
              #Find out if we are past the cutoff for today. If so, start counting from tomorrow
              if service.booking_details[:cutoff_time] and (Time.now.in_time_zone.seconds_since_midnight > service.booking_details[:cutoff_time].to_i)
                day = Time.now + 1.days 
              else
                day = Time.now
              end
              
              biz_days_count  = 0
              (0..max_notice_days).each do |n|
                if service.open_on_day? day
                  if biz_days_count >= min_notice_days
                    schedule = service.schedules.where(day: day.wday).first
                    if schedule
                      hours[day.strftime('%Y-%m-%d')] = {open: schedule.schedule_time_to_military_string(schedule.start_time), 
                        close: schedule.schedule_time_to_military_string(schedule.end_time)}
                    end
                  end
                  biz_days_count += 1
                end
                day = day + 1.days 
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

        render status: 200, json: hours

      end #hours

    end
  end
end
