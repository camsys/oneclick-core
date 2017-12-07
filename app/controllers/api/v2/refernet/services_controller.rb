module Api
  module V2
    module Refernet
      class ServicesController < ApiController


        # Overwrite the services index call in refernet so that we can add transportation info
        def index

          data = []
          duration_hash = {}
          
          sub_sub_category = OneclickRefernet::SubSubCategory.find_by(code: params[:sub_sub_category])
          sub_sub_category_services = sub_sub_category.try(:services) || []

          # Base service queries on a collection of UNIQUE services
          services = OneclickRefernet::Service.where(id: sub_sub_category_services
                                                          .pluck(:id)
                                                          .uniq)
          
          if params[:lat] and params[:lng]
            #services = sub_sub_category.services.closest(params[:lat], params[:lng]).confirmed.within_box(params[:lat], params[:lng], params[:meters] || 48280.3).uniq.limit(10)
            meters = (params[:meters].to_f > 0.0 ? params[:meters].to_f : 48280.3)
            services = services.closest(params[:lat], params[:lng])
                               .confirmed
                               .within_box(params[:lat], params[:lng], meters)
                               .limit(10)           
            duration_hash = build_duration_hash(params, services)
          else
            services = services.confirmed
                               .limit(10)
          end
          

          # TODO: NO HARD LIMIT. LIMIT BASED ON SOMETHING SMART E.G. DISTANCE
          services.each do |service|
            svc_data = service_hash(service, duration_hash)
            data << svc_data
          end

          render json: data

        end

        def email 
          OneclickRefernet::UserMailer.services(params[:email], params[:services], @locale).deliver
          render json: true
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
