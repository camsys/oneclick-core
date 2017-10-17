module Api
  module V2
    class ServiceSerializer < ActiveModel::Serializer

      attributes :id, :name, :type, :url, :email, :phone, :formatted_phone, 
                 :comments, :rating, :ratings_count
                 
      has_many :schedules
      
      def comments
        object.comments_hash
      end
      
      def schedules
        object.schedules.for_display
      end

    end
  end
end
