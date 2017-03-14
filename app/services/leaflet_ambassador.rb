module LeafletAmbassador

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Extend RGeo Point Class
  class RGeo::Geos::CAPIPointImpl
    def to_a
      [self.y, self.x]
    end
  end

  def unpack_polygon(polygon)
    [get_exterior_ring(polygon)] + get_interior_rings(polygon)
  end

  def get_exterior_ring(polygon)
    ring_to_array(polygon.exterior_ring)
  end

  def get_interior_rings(polygon)
    polygon.interior_rings.map { |ring| ring_to_array(ring) }
  end

  def ring_to_array(ring)
    ring.points.map{|p| p.to_a}
  end

  module ClassMethods

    # Dynamically define instance methods on including model
    def make_attribute_mappable(attr)

      define_method("#{attr}_to_array") do
        self.send(attr).map do |polygon|
          unpack_polygon(polygon)
        end
      end

      define_method("center_of_#{attr}") do
        self.send(attr).centroid.to_a
      end

    end

  end

end
