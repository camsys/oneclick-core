module Api
  module V2
    module Refernet
      class ServicesController < ApiController

        # Overwrite the services index call in refernet so that we can add transportation info
        def index
          duration_hash = {}
          
          sub_sub_category = OneclickRefernet::SubSubCategory.find_by(code: params[:sub_sub_category])
          sub_sub_category_services = sub_sub_category.try(:services) || []

          # Base service queries on a collection of UNIQUE services
          services = OneclickRefernet::Service.confirmed.where(id: sub_sub_category_services.pluck(:id).uniq)
          
          lat, lng = params[:lat], params[:lng]
          meters = params[:meters].to_f
          limit = params[:limit] || 10
          
          if lat && lng
            meters = meters > 0.0 ? meters : (30 * 1609.34) # Default to 30 miles
            
            services = services.closest(lat, lng)
                               .within_x_meters(lat, lng, meters)
                               .limit(limit)                  
            duration_hash = build_duration_hash(params, services)
          else
            services = services.limit(limit)
          end
          
          render json: services.map { |svc| service_hash(svc, duration_hash) }

        end
        
        def email 
          OneclickRefernet::UserMailer.services(params[:email], params[:services], @locale).deliver
          render json: true
        end

        def sms #TODO simplify this method and move the bulk of it to the Refernet Engine
          body = ""
          phone = PhonyRails.normalize_number(params[:phone], country_code: 'US')
          params[:services].each do |service_id|
            service = OneclickRefernet::Service.find(service_id)
            body += "#{service.to_s}\r\n#{service.address}"
          end

          sns = Aws::SNS::Client.new(
            region: ENV['AWS_SMS_REGION'],
            access_key_id: ENV['AWS_ACCESS_KEY_ID'] , 
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
     
          sns.publish({phone_number: phone, message: body})
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

        # Augments the ReferNET engine's service serializer, by adding in trip times from OTP
        def service_hash service, duration_hash={}
          base_service_hash = OneclickRefernet::ServiceSerializer
                              .new(service, 
                                   { scope: { locale: @locale} })
                              .to_hash
          base_service_hash.merge({
            "drive_time": duration_hash["#{service.id}_CAR"],
            "transit_time": duration_hash["#{service.id}_TRANSIT,WALK"],              
          })
        end

        # Call OTP and Pull out the durations
        def build_duration_hash(params, services)
          duration_hash ={}
          origin = [params[:lat], params[:lng]]
          otp = OTP::OTPService.new(Config.open_trip_planner)
            
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
