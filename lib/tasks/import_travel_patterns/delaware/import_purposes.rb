# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "DELGO Community Transit"
# agency = Agency.find_by(name: agency_name)
# purposes = Purpose.where(agency_id: agency.id).order(:name)
# purposes.map{|x| x.attributes.except("id", "agency_id", "created_at", "updated_at")}
[
  {"code"=>nil, "name"=>"Bank", "description"=>"DELGO Bank Trip Purpose"},
  {"code"=>nil, "name"=>"Cancer Treatment", "description"=>"DELGO Cancer Treatment Trip Purpose"},
  {"code"=>nil, "name"=>"Church", "description"=>"DELGO Church Trip Purpose"},
  {"code"=>nil, "name"=>"Dialysis", "description"=>"DELGO Dialysis Trip Purpose"},
  {"code"=>nil, "name"=>"Education", "description"=>"DELGO Education Trip Purpose"},
  {"code"=>nil, "name"=>"Medical", "description"=>"DELGO Medical Trip Purpose"},
  {"code"=>nil, "name"=>"Pharmacy", "description"=>"DELGO Pharmacy Trip Purpose"},
  {"code"=>nil, "name"=>"PhysicalTherapy", "description"=>"DELGO Physical Therapy Trip Purpose"},
  {"code"=>nil, "name"=>"Shopping", "description"=>"DELGO Shopping Trip Purpose"},
  {"code"=>nil, "name"=>"Therapy", "description"=>"DELGO Therapy Trip Purpose"},
  {"code"=>nil, "name"=>"Visit", "description"=>"DELGO Visit Trip Purpose"},
  {"code"=>nil, "name"=>"Volunteer", "description"=>"DELGO Volunteer Trip Purpose"},
  {"code"=>nil, "name"=>"Work", "description"=>"DELGO Work Trip Purpose"}
].each do | config_data|
  agency_name = "DELGO Community Transit"
  agency = Agency.find_by(name: agency_name)
  config = Purpose.find_by(name: config_data["name"], agency_id: agency.id)
  if config
    Rails.logger.info "Updating #{config_data["name"]}"
    config.update_attributes(config_data)
  else
    begin
      Rails.logger.info "Creating #{config_data["name"]}"
      purpose = Purpose.create!(
        :name => config_data["name"],
        :description => config_data["description"],
        :code => config_data["code"],
        :agency_id => agency.id,
        )
    rescue => e
      Rails.logger.warn e.message
    end
  end
end
