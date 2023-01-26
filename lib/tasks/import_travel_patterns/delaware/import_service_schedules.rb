# Script to transfer initial Travel Patterns data from QA to Production.
#
# Export data:
# agency_name = "DELGO Community Transit"
# agency = Agency.find_by(name: agency_name)
# service_schedules = ServiceSchedule.where(agency_id: agency.id).order(:name)
# service_schedules.map{|x| x.attributes.except("agency_id", "created_at", "updated_at").
#   merge({ service_sub_schedules: x.service_sub_schedules.map{|y| y.attributes.except("id", "agency_id", "created_at", "updated_at")}})}
# After export:
# Quote calendar_date
# Replace :service_sub_schedules with "service_sub_schedules"
[
  {"id"=>47, "service_schedule_type_id"=>2, "name"=>"DELGO Holiday Service Schedule", "description"=>"DELGO Holiday Service Schedule", "start_date"=>nil, "end_date"=>nil, "service_sub_schedules"=>[{"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Sat, 01 Jan2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 17 Jan 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 30 May 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 04 Jul 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 05 Sep 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 24 Nov 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Sun, 25 Dec 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Sun, 01 Jan 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 16 Jan 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 29 May 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Tue, 04 Jul 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 04 Sep 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 23 Nov 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 25 Dec 2023"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 01 Jan 2024"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 15 Jan 2024"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Fri, 27 May 2022"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 04 Jul 2024"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 02 Sep 2024"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 28 Nov2024"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Wed, 25 Dec 2024"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Wed, 01 Jan 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 20 Jan 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 26 May 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Fri, 04 Jul 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 01 Sep 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 27 Nov 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 25 Dec 2025"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 01 Jan 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 19 Jan 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 25 May 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Sat, 04 Jul 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 07 Sep 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 26 Nov 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Fri, 25 Dec 2026"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Fri, 01 Jan 2027"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 18 Jan 2027"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 31 May 2027"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Sun, 04 Jul2027"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Mon, 06 Sep 2027"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Thu, 25 Nov 2027"}, {"service_schedule_id"=>47, "day"=>nil, "start_time"=>nil, "end_time"=>nil, "calendar_date"=>"Sat, 25 Dec 2027"}]}, {"id"=>32, "service_schedule_type_id"=>1, "name"=>"DELGO Weekly Service Schedule", "description"=>"DELGO Standard Weekly Service Schedule", "start_date"=>nil, "end_date"=>nil, "service_sub_schedules"=>[{"service_schedule_id"=>32, "day"=>1, "start_time"=>25200, "end_time"=>61200, "calendar_date"=>nil}, {"service_schedule_id"=>32, "day"=>2, "start_time"=>25200, "end_time"=>61200, "calendar_date"=>nil}, {"service_schedule_id"=>32, "day"=>3, "start_time"=>25200, "end_time"=>61200, "calendar_date"=>nil}, {"service_schedule_id"=>32, "day"=>4, "start_time"=>25200, "end_time"=>61200, "calendar_date"=>nil}, {"service_schedule_id"=>32, "day"=>5, "start_time"=>25200, "end_time"=>61200, "calendar_date"=>nil}, {"service_schedule_id"=>32, "day"=>6, "start_time"=>25200, "end_time"=>61200, "calendar_date"=>nil}]}
].each do | config_data|
  agency_name = "DELGO Community Transit"
  agency = Agency.find_by(name: agency_name)
  config = ServiceSchedule.find_by(name: config_data["name"], agency_id: agency.id)
  if config
    Rails.logger.info "Updating #{config_data["name"]}"
    config.update_attributes(config_data.except("service_sub_schedules"))
    config.service_sub_schedules = []
    config_data["service_sub_schedules"].each do |config_sub_schedule|
      Rails.logger.info "Creating #{config_sub_schedule["calendar_date"]} #{config_sub_schedule["start_time"]} #{config_sub_schedule["end_time"]}"
      sub_schedule = ServiceSubSchedule.new
      sub_schedule.service_schedule = config
      sub_schedule.day = config_sub_schedule["day"]
      sub_schedule.start_time = config_sub_schedule["start_time"]
      sub_schedule.end_time = config_sub_schedule["end_time"]
      sub_schedule.calendar_date = config_sub_schedule["calendar_date"]
      sub_schedule.save!
    end
  else
    begin
      Rails.logger.info "Creating #{config_data["name"]}"
      service_schedule = ServiceSchedule.create!(
        :name => config_data["name"],
        :description => config_data["description"],
        :service_schedule_type_id => config_data["service_schedule_type_id"],
        :start_date => config_data["start_date"],
        :end_date => config_data["end_date"],
        :agency_id => agency.id,
        )
      service_schedule.service_sub_schedules = []
      config_data["service_sub_schedules"].each do |config_sub_schedule|
        Rails.logger.info "Creating #{config_sub_schedule["calendar_date"]} #{config_sub_schedule["start_time"]} #{config_sub_schedule["end_time"]}"
        sub_schedule = ServiceSubSchedule.new
        sub_schedule.service_schedule = service_schedule
        sub_schedule.day = config_sub_schedule["day"]
        sub_schedule.start_time = config_sub_schedule["start_time"]
        sub_schedule.end_time = config_sub_schedule["end_time"]
        sub_schedule.calendar_date = config_sub_schedule["calendar_date"]
        sub_schedule.save!
      end
    rescue => e
      Rails.logger.warn e.message
    end
  end
end
