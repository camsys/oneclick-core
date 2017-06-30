RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config| 
  config.default = RGeo::Geographic.spherical_factory(:srid => 4326) 
  # config.default = RGeo::Geos::CAPIFactory.new(:srid => 4326)
end
