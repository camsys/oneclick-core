module Api
  module V2
    class ServiceSerializer < ActiveModel::Serializer

      attributes :id, :name, :type, :url, :email, :phone, :formatted_phone, 
                 :comments, :rating, :ratings_count
                 
      has_many :schedules
      has_many :accommodations
      has_many :eligibilities
      has_many :purposes
      
      def comments
        object.comments_hash
      end
      
      def schedules
        object.schedules.for_display
      end
      
      def accommodations
        (object.accommodations || []).map(&:to_hash)
      end
      
      def eligibilities
        (object.eligibilities || []).map(&:to_hash)
      end
      
      def purposes
        (object.purposes || []).map(&:to_hash)
      end

    end
  end
end
