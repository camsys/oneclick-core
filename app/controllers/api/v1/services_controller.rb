module Api
  module V1
    class ServicesController < Api::V1::ApiController

      # FOR ECOLANEs
      def ids_humanized
        external_id_array = Service.paratransit_services.published.ecolane.each do |service|
          external_id_array += service.booking_details[:home_counties].split(',').map{ |x| x.strip }
        end
        external_id_array.map(&:humanize).uniq.sort
        hash = {service_ids: external_id_array}
        respond_with hash
      end

    end
  end
end
