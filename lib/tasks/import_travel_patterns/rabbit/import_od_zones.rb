# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "rabbittransit"
# agency = Agency.find_by(name: agency_name)
# od_zones = OdZone.where(agency_id: agency.id).order(:name)
# od_zones.map{|x| x.attributes.except("id", "agency_id", "region_id", "created_at", "updated_at").
#   merge({ region_recipe: x.region.recipe.to_s})}
# After Export:
# Replace :region_recipe with "region_recipe"
# Add region
[
  {"name"=>"Adams County", "description"=>"Adams County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Adams\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"CDH ADA Zone", "description"=>"CDH ADA Zone", "region_recipe"=>"[{:model=>\"CustomGeography\", :attributes=>{:name=>\"Fmr Ada Cdh 082022\", :buffer=>0}}]"}, {"name"=>"Columbia County", "description"=>"Columbia County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Columbia\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Columbia County and Geisinger Polygon", "description"=>"Columbia County and GeisingerPolygon", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Columbia\", :state=>\"PA\", :buffer=>\"500\"}}, {:model=>\"CustomGeography\", :attributes=>{:name=>\"Geisinger\", :buffer=>0}}, {:model=>\"City\", :attributes=>{:name=>\"MCSHERRYSTOWN (BORO) (ADAMS)\", :state=>\"PA\", :buffer=>0}}]"}, {"name"=>"Cumberland County", "description"=>"Cumberland County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Cumberland\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Dauphin County", "description"=>"Dauphin County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Dauphin\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Franklin County", "description"=>"Franklin County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Franklin\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Geisinger Polygon", "description"=>"Geisinger Polygon", "region_recipe"=>"[{:model=>\"CustomGeography\", :attributes=>{:name=>\"Geisinger\", :buffer=>0}}]"}, {"name"=>"Montour County", "description"=>"Montour County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Montour\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Northumberland County", "description"=>"Northumberland County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Northumberland\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Northumberland County and Geisinger Polygon", "description"=>"Northumberland County and Geisinger Polygon", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Northumberland\", :state=>\"PA\", :buffer=>\"500\"}}, {:model=>\"CustomGeography\", :attributes=>{:name=>\"Geisinger\", :buffer=>0}}]"}, {"name"=>"OCC-1072", "description"=>"", "region_recipe"=>"[{:model=>\"Landmark\", :attributes=>{:name=>\"Chapel Pointe\", :buffer=>500}}, {:model=>\"Landmark\", :attributes=>{:name=>\"EMERALD POINTE\", :buffer=>500}}]"}, {"name"=>"Perry County", "description"=>"Perry County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Perry\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Snyder County", "description"=>"Snyder County","region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Snyder\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"testing", "description"=>"delete me", "region_recipe"=>"[{:model=>\"LandmarkSet\", :attributes=>{:name=>\"testing\", :buffer=>\"5000\"}}, {:model=>\"LandmarkSet\", :attributes=>{:name=>\"testing786\", :buffer=>500}}, {:model=>\"CustomGeography\", :attributes=>{:name=>\"This Is Going To Be An Incredibly Long Name To Test The Ticket Occ 917 For The Truncation Of Names Of Things So We Shall See If This Is Long Enough To Achieve The Elipsies At The End Of The Title. Maybe?\", :buffer=>0}}]"}, {"name"=>"Union and Snyder Counties", "description"=>"Union and Snyder Counties", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Union\", :state=>\"PA\", :buffer=>\"500\"}}, {:model=>\"County\", :attributes=>{:name=>\"Snyder\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"Unionand Snyder Counties with Geisinger Polygon", "description"=>"Union and Snyder Counties with Geisinger Polygon", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Union\", :state=>\"PA\", :buffer=>\"500\"}}, {:model=>\"County\", :attributes=>{:name=>\"Snyder\", :state=>\"PA\", :buffer=>\"500\"}}, {:model=>\"CustomGeography\", :attributes=>{:name=>\"Geisinger\", :buffer=>0}}]"}, {"name"=>"Union County", "description"=>"Union County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Union\", :state=>\"PA\", :buffer=>\"500\"}}]"}, {"name"=>"York-Adams ADA Zone", "description"=>"York-Adams ADA Zone", "region_recipe"=>"[{:model=>\"CustomGeography\", :attributes=>{:name=>\"Fmr Ada Ya 082022\", :buffer=>0}}]"}, {"name"=>"York County", "description"=>"York County", "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"York\", :state=>\"PA\", :buffer=>\"0\"}}]"}
].each do | config_data|
  agency_name = "rabbittransit"
  agency = Agency.find_by(name: agency_name)
  config = OdZone.find_by(name: config_data["name"], agency_id: agency.id)
  if config
    Rails.logger.info "Updating #{config_data["name"]}"
    config.update_attributes(config_data.except("region_recipe"))
  else
    begin
      Rails.logger.info "Creating #{config_data["name"]}"
      od_zone = OdZone.create!(
        :name => config_data["name"],
        :description => config_data["description"],
        :agency_id => agency.id,
        )
      od_zone.build_geographies
      od_zone.save!
    rescue => e
      Rails.logger.warn e.message
    end
  end
end
