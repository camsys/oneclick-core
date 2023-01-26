# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "DELGO Community Transit"
# agency = Agency.find_by(name: agency_name)
# booking_windows = BookingWindow.where(agency_id: agency.id).order(:name)
# booking_windows.map{|x| x.attributes.except("id", "agency_id", "travel_pattern_id", "created_at", "updated_at")}
[
  {"name"=>"DELGO Default Booking Window", "description"=>"DELGO Default Booking Window", "minimum_days_notice"=>1, "maximum_days_notice"=>13, "minimum_notice_cutoff_hour"=>0}
].each do | config_data|
  agency_name = "DELGO Community Transit"
  agency = Agency.find_by(name: agency_name)
  config = BookingWindow.find_by(name: config_data["name"], agency_id: agency.id)
  if config
    Rails.logger.info "Updating #{config_data["name"]}"
    config.update_attributes(config_data)
  else
    begin
      Rails.logger.info "Creating #{config_data["name"]}"
      booking_window = BookingWindow.create!(
        :name => config_data["name"],
        :description => config_data["description"],
        :minimum_days_notice => config_data["minimum_days_notice"],
        :maximum_days_notice => config_data["maximum_days_notice"],
        :minimum_notice_cutoff_hour => config_data["minimum_notice_cutoff_hour"],
        :agency_id => agency.id,
        )
    rescue => e
      Rails.logger.warn e.message
    end
  end
end
