RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  
  # Only set default factory if Geos are supported. For some reason this breaks
  # Heroku deployment if assets aren't precompiled, but it works fine after
  # deployment is complete.
  if RGeo::Geos.supported?
    config.default = RGeo::Geos::CAPIFactory.new(:srid => 4326)
  end
  
end
