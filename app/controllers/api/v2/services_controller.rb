module Api
  module V2
    class ServicesController < ApiController
      
      # GET api/v2/services
      # Returns all published services; accepts URL param to filter by service type
      def index
        type = params[:type].to_s.titleize
        @services = Service.published
        @services = @services.where(type: type) if type.present?
        render(success_response(@services))
      end
      
    end
  end
end
