# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "rabbittransit"
# agency = Agency.find_by(name: agency_name)
# funding_sources = FundingSource.where(agency_id: agency.id).order(:name)
# funding_sources.map{|x| x.attributes.except("id", "agency_id", "created_at", "updated_at")}
[
  {"name"=>"AAA [21]", "description"=>"AAA [21] Funding Source"},
  {"name"=>"ACOFA", "description"=>"ACOFA Funding Source"},
  {"name"=>"ADA - Adams", "description"=>"ADA Funding Source for Adams County residents"},
  {"name"=>"ADA - HANOVER", "description"=>"ADA Funding Source for Hanover Area residents"},
  {"name"=>"ADA - YORK", "description"=>"ADA Funding Source for York County residents not in Hanover"},
  {"name"=>"CCAAA", "description"=>"Columbia County AAA Funding Source"},
  {"name"=>"D ADA", "description"=>"ADA Funding Source for Dauphin and Cumberland County residents"},
  {"name"=>"D Gen Pub", "description"=>"General Public Fare Funding Source for Dauphin County "},
  {"name"=>"D Lottery", "description"=>"Lottery Funding Source for Dauphin County"},
  {"name"=>"D PwD", "description"=>"PwD Funding Source for Dauphin County"},
  {"name"=>"FCAAA", "description"=>"AAA Funding Source for Franklin County"},
  {"name"=>"Find TP and delete this VA", "description"=>"VA Funding Source"},
  {"name"=>"Gen Pub", "description"=>"Gen Pub Funding Source"},
  {"name"=>"Gen Pub [21]", "description"=>"Gen Pub [21] Funding Source"},
  {"name"=>"Gen Public-US", "description"=>"Gen Public-US Funding Source"},
  {"name"=>"Gen Pub - MC", "description"=>"Gen Pub - MC Funding Source"},
  {"name"=>"Gen Pub-PC", "description"=>"Gen Pub-PC Funding Source"},
  {"name"=>"Lottery", "description"=>"Lottery Funding Source"},
  {"name"=>"Lottery [21]", "description"=>"Lottery [21] Funding Source"},
  {"name"=>"Lottery-MC", "description"=>"Lottery-MC"},
  {"name"=>"Lottery PC", "description"=>"Lottery PC Funding Source"},
  {"name"=>"Lottery - US", "description"=>"Lottery - US Funding Source"},
  {"name"=>"MATP", "description"=>"MATP Funding Source for Franklin, Adams and York Counties"},
  {"name"=>"MATP [21]", "description"=>"MATP Funding Source for Cumberland County"},
  {"name"=>"MATP-MC", "description"=>"MATP-MC Funding Source"},
  {"name"=>"MATP PC", "description"=>"MATP Funding Source for Perry County"},
  {"name"=>"MATP SR", "description"=>"MATP (old) Funding Source for Franklin County - is legacy funding source; check if being phased out"},
  {"name"=>"MATP - US", "description"=>"MATP - US Funding Source"},
  {"name"=>"MCAAA", "description"=>"MCAAA Funding Source"},
  {"name"=>"NCAAA", "description"=>"NCAAAFunding Source"},
  {"name"=>"PCAAA", "description"=>"PCAAA Funding Source"},
  {"name"=>"PWD", "description"=>"PWD Funding Source"},
  {"name"=>"PwD [21]", "description"=>"PwD [21] Funding Source"},
  {"name"=>"PwD-MC", "description"=>"PwD-MC Funding Source"},
  {"name"=>"PwD PC", "description"=>"PwD PC FundingSource"},
  {"name"=>"PwD-US", "description"=>"PwD-US Funding Source"},
  {"name"=>"PWD - York", "description"=>"PWD - York Funding Source"},
  {"name"=>"USAAA", "description"=>"USAAA Funding Source"},
  {"name"=>"YCAAA", "description"=>"YCAAA Funding Source"}
].each do | config_data|
  agency_name = "rabbittransit"
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
