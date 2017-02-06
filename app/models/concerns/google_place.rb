module GooglePlace
  
  def google_place_hash
    #Based on Google Place Details
    {
        address_components: self.google_address_components,

        formatted_address: "#{self.street_number} #{self.route}",
        geometry: {
          location: {
              lat: self.lat,
              lng: self.lng,
          }
        },

        id: self.id,
        name: self.name,
    }
  end

  def google_address_components
    address_components = []

    #Street Number
    if self.street_number
      address_components << {long_name: self.street_number, short_name: self.street_number, types: ['street_number']}
    end

    #Route
    if self.route
      address_components << {long_name: self.route, short_name: self.route, types: ['route']}
    end

    #City
    if self.city
      address_components << {long_name: self.city, short_name: self.city, types: ["locality", "political"]}
    end

    #State
    if self.state
      address_components << {long_name: self.state, short_name: self.state, types: ["postal_code"]}
    end

    #Zip
    if self.zip
      address_components << {long_name: self.zip, short_name: self.zip, types: ["administrative_area_level_1","political"]}
    end

    return address_components

  end
end