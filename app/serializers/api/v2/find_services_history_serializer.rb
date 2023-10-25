module Api
  module V2

    class FindServicesHistorySerializer < ApiSerializer
      
      attributes  :id,
                  :user_starting_location,
                  :service_sub_sub_category
      belongs_to :user
      
    end
    
  end
end
