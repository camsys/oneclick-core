module Api
  module V2
    class ServiceSerializer < ActiveModel::Serializer

      attributes :id, :name, :type, :url, :email, :phone, :formatted_phone, 
                 :comments, :rating, :ratings_count
      
      def comments
        object.comments_hash
      end

    end
  end
end
