# Geographic records, this is the projection code to use
Rails.application.config.srid = 4326


RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config| 
  # config.default = RGeo::Geographic.spherical_factory(srid: 4326) 
  config.default = RGeo::Geos::CAPIFactory.new(:srid => 4326)
end
