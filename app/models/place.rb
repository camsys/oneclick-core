class Place < ApplicationRecord

  self.abstract_class = true
  attr_accessor :google_place_attributes
  before_save :build_geometry

  #### Includes ####
  include GooglePlace

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

  # Returns an RGeo point object based on lat and lng
  def to_point
    RGeo::Geographic.spherical_factory(:srid => Config.srid).point(lng, lat)
  end
  
  # Builds its own geometry column based on lat and lng columns
  def build_geometry
    self.geom = to_point
  end

end
