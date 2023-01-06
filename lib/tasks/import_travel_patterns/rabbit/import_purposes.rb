# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "rabbittransit"
# agency = Agency.find_by(name: agency_name)
# purposes = Purpose.where(agency_id: agency.id).order(:name)
# purposes.map{|x| x.attributes.except("id", "agency_id", "created_at", "updated_at")}
[
  {"code"=>nil, "name"=>"ADA", "description"=>"ADA Trip Purpose"},
  {"code"=>nil, "name"=>"Adult Day Care", "description"=>"Adult Day Care Trip Purpose"},
  {"code"=>nil, "name"=>"Bank", "description"=>"Bank Trip Purpose"},
  {"code"=>nil, "name"=>"Beauty Salon", "description"=>"Beauty Salon Trip Purpose"},
  {"code"=>nil, "name"=>"Church", "description"=>"Church Trip Purpose"},
  {"code"=>nil, "name"=>"Day Care", "description"=>"Day Care Trip Purpose"},
  {"code"=>nil, "name"=>"Day Care/Alt (16)", "description"=>"Day Care/Alt (16) Trip Purpose"},
  {"code"=>nil, "name"=>"Dialysis", "description"=>"Dialysis Trip Purpose"},
  {"code"=>nil, "name"=>"Dining", "description"=>"Dining Trip Purpose"},
  {"code"=>nil, "name"=>"Education", "description"=>"Education Trip Purpose"},
  {"code"=>nil, "name"=>"Employment", "description"=>"Employment Trip Purpose"},
  {"code"=>nil, "name"=>"Fitness/PT", "description"=>"Fitness/PT Trip Purpose"},
  {"code"=>nil, "name"=>"Food Bank", "description"=>"Food Bank Trip Purpose"},
  {"code"=>nil, "name"=>"Grocery", "description"=>"Grocery Trip Purpose"},
  {"code"=>nil, "name"=>"Grocery Shop", "description"=>"Grocery Shop Trip Purpose"},
  {"code"=>nil, "name"=>"Hair Dresser", "description"=>"Hair Dresser Trip Purpose"},
  {"code"=>nil, "name"=>"Hospitalization", "description"=>"Hospitalization Trip Purpose"},
  {"code"=>nil, "name"=>"Human Services", "description"=>"Human Services Trip Purpose"},
  {"code"=>nil, "name"=>"Laundry [21]", "description"=>"Laundry [21] Trip Purpose"},
  {"code"=>nil, "name"=>"Library [21]", "description"=>"Library [21] Trip Purpose"},
  {"code"=>nil, "name"=>"Lifeskills", "description"=>"Lifeskills Trip Purpose"},
  {"code"=>nil, "name"=>"Medical", "description"=>"Medical Trip Purpose"},
  {"code"=>nil, "name"=>"Methadone", "description"=>"Methadone Trip Purpose"},
  {"code"=>nil, "name"=>"Nutrition", "description"=>"Nutrition Trip Purpose"},
  {"code"=>nil, "name"=>"Pharmacy", "description"=>"Pharmacy Trip Purpose"},
  {"code"=>nil, "name"=>"Physical Therapy", "description"=>"Physical Therapy Trip Purpose"},
  {"code"=>nil, "name"=>"Post Office [21]", "description"=>"Post Office [21] Trip Purpose"},
  {"code"=>nil, "name"=>"Recreation", "description"=>"Recreation Trip Purpose"},
  {"code"=>nil, "name"=>"Rec/Social", "description"=>"Rec/Social Trip Purpose"},
  {"code"=>nil, "name"=>"Senior Center", "description"=>"Senior Center Trip Purpose"},
  {"code"=>nil, "name"=>"Shopping", "description"=>"Shopping Trip Purpose"},
  {"code"=>nil, "name"=>"Social Service", "description"=>"Social Service Trip Purpose"},
  {"code"=>nil, "name"=>"Visiting", "description"=>"Visiting Trip Purpose"},
  {"code"=>nil, "name"=>"Volunteer", "description"=>"Volunteer Trip Purpose"},
  {"code"=>nil, "name"=>"Volunteer Work", "description"=>"Volunteer Work Trip Purpose"},
  {"code"=>nil, "name"=>"Work", "description"=>"Work Trip Purpose"}
].each do | config_data|
  agency_name = "rabbittransit"
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
