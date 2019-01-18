module Api
  module V1
    class ServicesController < ApiController

      # FOR ECOLANEs
      def ids_humanized
        external_id_array = []
        Service.paratransit_services.published.is_ecolane.each do |service|
          external_id_array += service.booking_details[:home_counties].split(',').map{ |x| x.strip }
        end
        render status: 200, json: {service_ids: external_id_array.map(&:humanize).uniq.sort}
      end

    end
  end
end
