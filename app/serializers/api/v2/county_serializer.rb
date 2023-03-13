module Api
  module V2
    class CountySerializer < ApiSerializer

      attributes  :id, 
                  :name, 
                  :state
      
    end
  end
end