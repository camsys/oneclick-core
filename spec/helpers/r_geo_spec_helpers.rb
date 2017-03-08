module RGeoSpecHelpers
  class RGeoSpecHelper
    def initialize(factory=RGeo::Geographic.spherical_factory(srid: 4326))
      @factory = factory
    end

    def point(lat=40,lng=-80)
      @factory.point(lat,lng)
    end

    def points
      [
        point(40,-80),
        point(41,-80),
        point(41,-79),
        point(40,-79)
      ]
    end

    def polygon(pts=points)
      @factory.polygon(@factory.linear_ring(pts))
    end

    def multi_polygon(polys=[polygon])
      @factory.multi_polygon(polys)
    end
  end

end
