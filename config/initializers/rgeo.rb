RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config| 
  config.default = RGeo::Geos::CAPIFactory.new(:srid => 4326)
end
