module Api
  module V2
    class ServicesController < ApiController
      
      # GET api/v2/services
      # Returns all published services; accepts URL param to filter by service type
      def index
        type = params[:type].to_s.titleize
        @services = Service.published
        @services = @services.where(type: type) if type.present?
        render(success_response(@services.order(:name)))
      end

      def show

        if params[:id].to_i.nonzero?
          @service = Service.published.find_by(id: params[:id])
        end
        render(success_response(@service))
      end
      
    end
  end
end
