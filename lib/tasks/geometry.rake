namespace :geometry do
  task load_counties: :environment do
    # uses_lenient_assertions is so that it doesn't take forever to go through.
    # Should probably just pre-filter county shapefiles and turn that off.
    factory = RGeo::Geographic.spherical_factory(srid: 4326, uses_lenient_assertions: true)
    RGeo::Shapefile::Reader.open(Rails.root.to_s + '/tmp/shapefiles/county.shp', factory: factory) do |file|
      file.each do |record|
        state = record['STATE']
        name = record['NAME']
        if Config.states.include?(state)
          geom = record.geometry
          print "Loading #{name}, #{state}..."
          if County.first_or_create(name: name, state: state, geom: geom)
            puts " ...SUCCESS!"
          else
            puts " ...FAILURE. :("
          end
        else
          puts "#{name}, #{state} is not in valid area."
        end
      end
    end
  end
end
