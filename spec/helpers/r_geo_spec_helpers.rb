module RGeoSpecHelpers
  class RGeoSpecHelper
    def initialize(factory=RGeo::Geographic.simple_mercator_factory(srid: 4326))
      @factory = factory
    end

    def point(lat,lng)
      @factory.point(lat,lng)
    end

    def points(offset=[0,0])
      lat, lng = 42.393936 + offset[0], -71.144578 + offset[1]
      [
        point(lng + 1, lat + 1),
        point(lng - 1, lat + 1),
        point(lng - 1, lat - 1),
        point(lng + 1, lat - 1)
      ]
    end

    def polygon(offset=[0,0])
      @factory.polygon(@factory.linear_ring(points(offset)))
    end

    def multi_polygon(offset=[0,0])
      @factory.multi_polygon([polygon(offset)])
    end
  end

end
