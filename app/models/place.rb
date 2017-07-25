class Place < ApplicationRecord

  self.abstract_class = true
  attr_accessor :google_place_attributes
  before_save :build_geometry
  
  #### Includes ####
  include GooglePlace

  # Search over all classes that inherit from place by query string
  def self.get_by_query_str(query_str, limit, user=nil)
    rel = nil
    if user
      rel = self.where(user: user).arel_table[:name].lower().matches(query_str)
    else
      rel = self.arel_table[:name].lower().matches(query_str)
    end
    self.where(rel).limit(limit)
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

end
