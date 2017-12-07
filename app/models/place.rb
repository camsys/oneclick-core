class Place < ApplicationRecord

  self.abstract_class = true
  attr_accessor :google_place_attributes
  before_save :build_geometry
    
  #### Includes ####
  include GooglePlace

  # Search over all classes that inherit from place by query string
  def self.get_by_query_str(query_str)
    rel = self.arel_table[:name].lower().matches(query_str)
    self.unique.where(rel)
  end

  # Returns a collection of each of the first unique records by name, lat, and lng
  def self.unique
    where(id: self.group(:name,:lat,:lng).maximum(:id).values)
  end

  # If a google_place_attributes param is passed, will create a Place based on the JSON contained therein.
  def self.new attrs=nil
    if attrs && attrs[:google_place_attributes]
      initialize_from_google_place_attributes(attrs[:google_place_attributes])
    else
      super
    end
  end

  # Converts google place attributes to readable format before initializing as normal
  def self.initialize_from_google_place_attributes(attrs=nil)
    self.new(attrs_from_google_place(attrs))
  end

  # Converts google place attributes to readable format before updating as normal
  def update_from_google_place_attributes(attrs=nil)
    self.update_attributes(Place.attrs_from_google_place(attrs))
  end
  
  # Returns an RGeo point object based on lat and lng
  def to_point
    factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.default
    factory.point(lng, lat)
  end
  
  # Builds its own geometry column based on lat and lng columns
  def build_geometry
    self.geom = to_point
  end
  
  # Returns true if place's name, lat, and lng match the given place
  def similar_to?(other_place)
    name == other_place[:name] &&
    lat == other_place[:lat] &&
    lng == other_place[:lng]
  end
    

end
