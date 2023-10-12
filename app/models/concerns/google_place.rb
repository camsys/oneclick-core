module GooglePlace
  ADDRESS_COMPONENTS = {
    # street_address: ["street_address"],
    street_number: ["street_number"],
    route: ["route"],
    city: ["locality", "political"],
    zip: ["postal_code"],
    state: ["administrative_area_level_1", "political"],
    county: ["administrative_area_level_2", "political"]
  }

  def self.included(base)
    base.extend(ClassMethods)
  end

  def google_place_hash
    if self.name && self.name.respond_to?(:split)
      split_name = self.name.split('|')
      filtered_name = split_name.first ? split_name.first.strip : self.name
    else
      filtered_name = self.name
    end
    
    {
      address_components: self.address_components,
      formatted_address: self.formatted_address,
      geometry: self.geometry,
      id: self.id,
      name: (filtered_name == self.auto_name) ? "" : filtered_name
    }
  end  

  # Returns an array of google address components hashes based on the place's attributes
  def address_components
    return ADDRESS_COMPONENTS
      .map do |occ_name, google_types|
        { long_name: self.send(occ_name),
          short_name: self.send(occ_name),
          types: google_types }
      end
  end
  
  # Creates a geometry hash from lat and lng
  def geometry
    {
      location: {
          lat: self.lat.to_s,
          lng: self.lng.to_s,
      }
    }
  end

  class GooglePlaceHash < HashWithIndifferentAccess

    def to_attrs
      attrs = {
        name: self[:name],
        lat: self[:geometry][:location][:lat],
        lng: self[:geometry][:location][:lng]
      }.merge(unpack_address_components)
      return attrs
    end

    def unpack_address_components
      address_components = self[:address_components]
      address_attributes = {}
      ADDRESS_COMPONENTS.each do |k,v|
        component = get_address_component_by_type(v)
        address_attributes[k] = component.first[:long_name] unless component.empty?
      end
      return address_attributes
    end

    def get_address_component_by_type(types)
      types = types.is_a?(Array) ? types : [types]
      self[:address_components].select {|ac| types.all? {|type| ac[:types].include?(type.to_s)} }
    end
  end

  module ClassMethods
    def attrs_from_google_place(google_place_attributes)
      if google_place_attributes.is_a? String 
        # This is JSON parse it before passing it
        GooglePlaceHash[JSON.parse(google_place_attributes)].to_attrs
      else
        # This has already been parsed
        GooglePlaceHash[google_place_attributes].to_attrs
      end
    end
  end
end
