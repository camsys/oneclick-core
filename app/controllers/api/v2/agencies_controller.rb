module Api
  module V2
    class AgenciesController < ApiController
      before_action :load_agencies
            
      # Gets all (published) agencies. An optional type parameter will filter
      # by agency type (e.g. TransportationAgency, PartnerAgency)
      def index

        # Filter by Agency Type if type param is passed
        type_name = params[:type].to_s.strip.titleize + "Agency"
        type_name = Agency.agency_type_names.include?(type_name) ? type_name : nil
        @agencies = @agencies.where(type: type_name) if type_name

        render success_response(
            @agencies, 
            serializer: AgencySerializer, 
            root: "agencies")
      end
      
      protected
      
      # Scope agencies to published only
      def load_agencies
        @agencies = Agency.published.order(:name)
      end
      
    end
  end
end
