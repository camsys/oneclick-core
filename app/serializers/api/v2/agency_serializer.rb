module Api
  module V2
    class AgencySerializer < ApiSerializer
      attributes  :id, :name, :type, :logo, :phone, :formatted_phone, :email, :url, :description
      
      def self.collection_serialize(collection)
        ActiveModelSerializers::SerializableResource.new(collection, each_serializer: self)
      end

      def logo
        object.full_logo_url
      end
      
      def description
        object.description(locale)
      end
      
    end
  end
end
