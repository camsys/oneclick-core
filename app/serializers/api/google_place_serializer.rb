module Api
  
  # For serializing Place records as Google Places. 
  # Assumes serialized object includes the GooglePlace module.
  class GooglePlaceSerializer < ApiSerializer
    
    attributes :address_components, :formatted_address, :geometry, :id, :name
    
  end
  
end
