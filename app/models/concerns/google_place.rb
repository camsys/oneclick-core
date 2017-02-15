module GooglePlace

  def self.included(base)
    base.extend(ClassMethods)
  end

  def google_place_hash
    #Based on Google Place Details
    GooglePlaceHash[
        address_components: self.google_address_components,
        formatted_address: "#{self.street_number} #{self.route}",
        geometry: {
          location: {
              lat: self.lat.to_s,
              lng: self.lng.to_s,
          }
        },
        id: self.id,
        name: self.name
    ]
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

  class GooglePlaceHash < HashWithIndifferentAccess
    @@ADDRESS_COMPONENTS = {
      # street_address: ["street_address"],
      street_number: ["street_number"],
      route: ["route"],
      city: ["locality", "political"],
      state: ["postal_code"],
      zip: ["administrative_area_level_1", "political"]
    }

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
      @@ADDRESS_COMPONENTS.each do |k,v|
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
      GooglePlaceHash[JSON.parse(google_place_attributes)].to_attrs
    end
  end
end
