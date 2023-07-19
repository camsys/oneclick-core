module Api
  module V2
    module Refernet
      class ServicesController < ApiController
        before_action :ensure_traveler, only: [:collect_history] #If @traveler is not set, then create a guest user account

        include ActionView::Helpers::NumberHelper
        # Endpoint is: /api/v2/oneclick_refernet/services
        # - plus any query params attached to the request
        # Overwrite the services index call in refernet so that we can add transportation info
        def index
          duration_hash = {}
          
          sub_sub_category = OneclickRefernet::SubSubCategory.find_by(code: params[:sub_sub_category])
          sub_sub_category_services = sub_sub_category.try(:services) || []

          # Base service queries on a collection of UNIQUE services
          services = OneclickRefernet::Service.confirmed.where(id: sub_sub_category_services.pluck(:id).uniq)
          
          lat, lng = params[:lat], params[:lng]
          meters = (params[:meters] || OneclickRefernet.try(:default_radius_meters)).to_f
          limit = params[:limit] || 10
          
          if lat && lng
            meters = meters > 0.0 ? meters : (30 * 1609.34) # Default to 30 miles
            
            services = services.closest(lat, lng)
                               .within_x_meters(lat, lng, meters)
                               .limit(limit)
            # This is where OTP is called to get trip duration by public transit and by vehicle
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
            body += "#{service.to_s}\r\n#{service.address}\r\n"
            if service.phone 
              body += "#{number_to_phone(service.phone)}\r\n"
            end
          end

          sns = Aws::SNS::Client.new(
            region: ENV['AWS_SMS_REGION'],
            access_key_id: ENV['AWS_ACCESS_KEY_ID'] , 
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
     
          begin
            sns.publish({phone_number: phone, message: body})
            render(success_response())
          rescue => exception
            render(fail_response(status: 400, message: "Invalid Request"))
          end

        end

        # API call to create find services history records from Find Services workflow.
        def create_find_services_history
          # User starting location e.g. "Ventura, CA"
          formatted_address = params[:formatted_address]
          lat = params[:lat]
          lng = params[:lng]
          # Service sub-sub-category e.g. "Congregate Meal/Nutrition Sites"
          sub_sub_category_name = params[:sub_sub_category_name]

          # Create history record
          @find_services_history = FindServicesHistory.new
          @find_services_history.user_starting_location = formatted_address
          @find_services_history.user_starting_lat = lat
          @find_services_history.user_starting_lng = lng
          @find_services_history.service_sub_sub_category = sub_sub_category_name
          success = @find_services_history.save

          if success
            # Add user information
            @find_services_history.user = @traveler
            @find_services_history.user_ip = @traveler.current_sign_in_ip
            if !@find_services_history.save
              Rails.logger.debug "Unable to update find_services_history user"
            end
            render(success_response(@find_services_history, serializer_opts: {include: ['*.*.*']}))
          else
            Rails.logger.debug "Unable to create find_services_history"
          end
        end

        # API call to update find services history records from Find Services workflow.
        # Modify history record to add associated trip id for trip planned through services.
        def update_find_services_history_trip_id
          find_services_history_id = params[:find_services_history_id]
          trip_id = params[:trip_id]
          # Find existing history record to update.
          @find_services_history = FindServicesHistory.find(find_services_history_id)
          if @find_services_history
            if @find_services_history.trip_id.nil?
              # Add trip id for the planned trip.
              if !@find_services_history.update(trip_id: trip_id)
                Rails.logger.debug "Unable to update find_services_history trip_id"
              end
            else
              # Trip id has already been set.
              # Copy the find services record for the re-planned trip.
              @find_services_history = @find_services_history.dup
              @find_services_history.trip_id = trip_id
              if !@find_services_history.save
                Rails.logger.debug "Unable to copy find_services_history"
              end
            end
          end

          render(success_response(@find_services_history, serializer_opts: {include: ['*.*.*']}))
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
          otp_version = Config.open_trip_planner_version
          otp = OTP::OTPService.new(Config.open_trip_planner, otp_version)
            
          ### Build the requests
          requests = []
          otp_v1_modes = ['TRANSIT,WALK', 'CAR'] 
          otp_v2_modes = ['TRANSIT,WALK', 'CAR_PARK,TRANSIT', 'CAR']
          modes = otp_version ? otp_v1_modes : otp_v2_modes
          services.each do |service|
            unless service.latlng.nil?
              modes.each do |mode|
                new_request = build_request(origin, service, mode)
                unless new_request.nil? 
                  requests << new_request
                end
              end 
            end
          end 

          # If there are no requests to make, return an emptry duration hash.
          if requests.count == 0
            return {}
          end

          ### Make the Call
          successful_plans = {}
          [1,2,3,4,5].each do |i|
            puts "Calling OTP with #{requests.count} requests. This is attempt #{i}"

            plans = otp.multi_plan([requests])

            # Check to see if we had any successes? 
            if plans and plans[:callback]
              successful_plans.merge! plans[:callback]
            end

            # Check to see if we had any failures. OTP Can get overwhelmed sometimes, and we have to try again.
            failures = plans[:errback].keys 
            if failures.nil? or failures.count == 0
              break
            end
            sleep 1 # Sleep is a blocking operation. We should think of a way to do this on another thread.
            requests = requests.select{ |req| req[:label].in? failures }
          end

          ### Unack the requests and build a hash of durations
          successful_plans.each do |label, plan| 
            response = otp.unpack(plan.response)
            itinerary = response.extract_itineraries.first
            duration_hash[label] = itinerary.nil? ? nil : itinerary.itinerary["duration"]
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
