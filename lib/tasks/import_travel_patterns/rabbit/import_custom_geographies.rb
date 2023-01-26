# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "rabbittransit"
# agency = Agency.find_by(name: agency_name)
# custom_geos = CustomGeography.order(:name)
# custom_geos.map{|x| x.attributes.except("id", "agency_id", "geom", "created_at", "updated_at")}
[
  {"name"=>"Ada Dubfr", "description"=>nil}, {"name"=>"Ada Mtn Mid", "description"=>nil}, {"name"=>"Ada Puxfr", "description"=>nil}, {"name"=>"Ada Pux To Dub", "description"=>nil}, {"name"=>"Ata Polygon", "description"=>nil}, {"name"=>"Brookville Cab Sa", "description"=>nil}, {"name"=>"Dub Cab Sa", "description"=>nil}, {"name"=>"Fmr Ada Cdh 082022", "description"=>nil}, {"name"=>"Fmr Ada Ya 082022", "description"=>nil}, {"name"=>"Fmr Ada Ya 082022 Copy", "description"=>nil}, {"name"=>"Geisinger", "description"=>nil}, {"name"=>"Hazleton Ada", "description"=>nil}, {"name"=>"Jefferson Cws Sa", "description"=>nil}, {"name"=>"Lcta Ada", "description"=>nil}, {"name"=>"Pennsylvania State Boundary", "description"=>nil}, {"name"=>"Pxy Cab Sa", "description"=>nil}, {"name"=>"Testing Deleted Angecies", "description"=>nil}, {"name"=>"This Is Going To Be An Incredibly Long Name To Test The Ticket Occ 917 For The Truncation Of Names Of Things So We Shall See If This Is Long Enough To Achieve The Elipsies At The End Of The Title. Maybe?", "description"=>nil}, {"name"=>"Wintest", "description"=>nil}
].each do | config_data|
  agency_name = "rabbittransit"
  agency = Agency.find_by(name: agency_name)
  config = CustomGeography.find_by(name: config_data["name"], agency_id: agency.id)
  if config
    Rails.logger.info "Updating #{config_data["name"]}"
    config.update_attributes(config_data)
  else
    begin
      Rails.logger.info "Creating #{config_data["name"]}"
      custom_geo = CustomGeography.create!(
        :name => config_data["name"],
        :description => config_data["description"],
        :agency_id => agency.id,
        )
    rescue => e
      Rails.logger.warn e.message
    end
  end
end
