class Waypoint < Place
  has_one :trip_as_origin, foreign_key: "origin_id", class_name: "Trip"
  has_one :trip_as_destination, foreign_key: "destination_id", class_name: "Trip"
  before_save :build_geometry

  def trip
    trip_as_origin || trip_as_destination
  end
  
  # Returns a full formatted address string
  def address
    [
      [street_number, route].compact.join(' '),
      city,
      [state, zip].compact.join(' ')
    ].compact.join(', ')
  end
  
  def to_s
    address
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
