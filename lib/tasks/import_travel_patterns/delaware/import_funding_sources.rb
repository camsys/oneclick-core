# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "DELGO Community Transit"
# agency = Agency.find_by(name: agency_name)
# funding_sources = FundingSource.where(agency_id: agency.id).order(:name)
# funding_sources.map{|x| x.attributes.except("id", "agency_id", "created_at", "updated_at")}
[
  {"name"=>"Lottery", "description"=>"DELGO Lottery Funding Source"},
  {"name"=>"MATP", "description"=>"DELGO MATP Funding Source"}
].each do | config_data|
  agency_name = "DELGO Community Transit"
  agency = Agency.find_by(name: agency_name)
  config = FundingSource.find_by(name: config_data["name"], agency_id: agency.id)
  if config
    Rails.logger.info "Updating #{config_data["name"]}"
    config.update_attributes(config_data)
  else
    begin
      Rails.logger.info "Creating #{config_data["name"]}"
      funding_source = FundingSource.create!(
        :name => config_data["name"],
        :description => config_data["description"],
        :agency_id => agency.id,
        )
    rescue => e
      Rails.logger.warn e.message
    end
  end
end
