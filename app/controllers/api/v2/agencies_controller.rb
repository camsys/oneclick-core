module Api
  module V2
    class AgenciesController < ApiController
            
      # Gets all agencies. An optional type parameter will filter by agency type
      # (e.g. TransportationAgency, PartnerAgency)
      def index

        # Filter by Agency Type if type param is passed
        type_name = params[:type].to_s.strip.titleize + "Agency"
        type_name = Agency.agency_type_names.include?(type_name) ? type_name : nil
        @agencies = type_name ? Agency.where(type: type_name) : Agency.all

        render success_response(
            @agencies, 
            serializer: AgencySerializer, 
            root: "agencies")
      end
      
    end
  end
end
