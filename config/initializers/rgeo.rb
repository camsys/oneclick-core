RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  puts "CHECKING RGEO SUPPORT..."
  if RGeo::Geos.supported?
    puts "GEOS SUPPORTED!"
    config.default = RGeo::Geos::CAPIFactory.new(:srid => 4326)
  else
    puts "GEOS NOT SUPPORTED :("
  end
end
