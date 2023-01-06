# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "DELGO Community Transit"
# agency = Agency.find_by(name: agency_name)
# od_zones = OdZone.where(agency_id: agency.id).order(:name)
# od_zones.map{|x| x.attributes.except("id", "agency_id", "created_at", "updated_at").
#   merge({ region_recipe: x.region.recipe.to_s})}
# After Export:
# Replace :region_recipe with "region_recipe"
# Add region
[
  {"name"=>"Delaware County", "description"=>"Delaware County", "region_id"=>131, "region_recipe"=>"[{:model=>\"County\", :attributes=>{:name=>\"Delaware\", :state=>\"PA\", :buffer=>\"0\"}}]"}
].each do | config_data|
  agency_name = "DELGO Community Transit"
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
