module GooglePlace
  ADDRESS_COMPONENTS = {
    # street_address: ["street_address"],
    street_number: ["street_number"],
    route: ["route"],
    city: ["locality", "political"],
    state: ["postal_code"],
    zip: ["administrative_area_level_1", "political"]
  }

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

  # Returns an array of google address components hashes based on the place's attributes
  def google_address_components
    return ADDRESS_COMPONENTS
      .select {|occ_name,_| self.send(occ_name) }
      .map do |occ_name, google_types|
        { long_name: self.send(occ_name), short_name: self.send(occ_name), types: google_types }
      end
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
      GooglePlaceHash[JSON.parse(google_place_attributes)].to_attrs
    end
  end
end
