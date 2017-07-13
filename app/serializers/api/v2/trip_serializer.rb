module Api
  module V2

    class TripSerializer < ActiveModel::Serializer
      
      attributes  :id, 
                  :arrive_by, 
                  :trip_time
      has_many :itineraries
      belongs_to :user
      belongs_to :origin
      belongs_to :destination
      
    end
    
  end
end
