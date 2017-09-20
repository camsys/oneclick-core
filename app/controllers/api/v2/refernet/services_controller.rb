module Api
  module V2
    module Refernet
      class ServicesController < ApiController
      
        # Overwrite the services index call in refernet so that we can add transportation info
        def index
          data = []
          duration_hash = {}
          
          sub_sub_category = OneclickRefernet::SubSubCategory.find_by(name: params[:sub_sub_category])
          services = sub_sub_category.services.confirmed.uniq.limit(10)
          
          if params[:lat] and params[:lng]
            duration_hash = build_duration_hash(params, services)
          end

          # TODO: NO HARD LIMIT. LIMIT BASED ON SOMETHING SMART E.G. DISTANCE
          services.each do |service|
            svc_data = service_hash(service, duration_hash)
            data << svc_data
          end 

          render json: data

        end

        protected

        # Builds the request to be sent to OTP
        def build_request origin, service, mode="TRANSIT,WALK"

          if service.latlng.nil? 
            return nil
          end

          {
            from: [
              origin[0],
              origin[1]
            ],
            to: [
              service.lat.to_s,
              service.lng.to_s
            ],
            trip_time:  Time.now,
            arrive_by: true,
            label: "#{service.id}_#{mode}",
            options: {
              mode: mode,
              num_itineraries: 1
            }
          }
        end

        # Acts as a serializer for refernet services
        def service_hash service, duration_hash={}

          display_url = service['details']['url'] || service['details']['PUrl'] || service['details']['LUrl']

          { "service_id": service["Service_ID"],
            "agency_name": service['agency_name'],
            "site_name": service['site_name'],
            "lat": service.latlng? ? service.lat : nil,
            "lng": service.latlng? ? service.lng : nil,
            "address": service.address,
            "phone": service['details']["Number_Phone1"],
            "drive_time": duration_hash["#{service.id}_CAR"],
            "transit_time": duration_hash["#{service.id}_TRANSIT,WALK"],
            "display_url": display_url,
            "url": full_url(display_url), #Ensure that the URL starts with http://
            "description":  service['details']["Label_Service Description"] || "#{service['details']['Note1']} #{service['details']['Note2']}" 
          }
        end

        # Call OTP and Pull out the durations
        def build_duration_hash(params, services)
          duration_hash ={}
          origin = [params[:lat], params[:lng]]
          otp = OTPServices::OTPService.new(Config.open_trip_planner)
            
          ### Build the requests
          requests = []
          services.each do |service|
            unless service.latlng.nil?
              ['TRANSIT,WALK', 'CAR'].each do |mode|
                new_request = build_request(origin, service, mode)
                unless new_request.nil? 
                  requests << new_request
                end
              end 
            end
          end 

          ### Make the Call
          plans = otp.multi_plan([requests])

          ### Unack the requests and build a hash of durations
          unless plans.nil? or plans[:callback].nil?
            plans[:callback].each do |label, plan|
              response = otp.unpack(plan.response)
              itinerary = response.extract_itineraries.first
              duration_hash[label] = itinerary.nil? ? nil : itinerary.itinerary["duration"]
            end
          end
          return duration_hash
        end

        # Check to see if we need to prepend http:// onto the display URL
        def full_url display_url
          if display_url.blank?
            return nil
          end
          return (display_url[0..6] == "http://" or display_url[0..7] == "https://") ? display_url : "http://#{display_url}"
        end
      
      end
    end
  end
end
