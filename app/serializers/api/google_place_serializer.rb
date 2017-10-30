module Api
  
  # For serializing Place records as Google Places. Assumes class includes the GooglePlace module.
  class GooglePlaceSerializer < ApiSerializer
    
    attributes :address_components, :formatted_address, :geometry, :id, :name
    
  end
  
end
