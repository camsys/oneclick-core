RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config| 
  puts "GEOS AVAILABLE?", RGeo::Geos.supported?
  # config.default = RGeo::Geos::CAPIFactory.new(:srid => 4326)
end
