namespace :ecolane do
  desc "Update Ecolane POIs"
  task :update_pois => :environment do
    is_already_running = false
    task_run_state = Config.find_or_create_by key: 'ecolane_task_is_running'
    task_run_state.with_lock do
      task_run_state.reload
      is_already_running = task_run_state.value
      if is_already_running && task_run_state.updated_at > (DateTime.now - 1.day)
        puts "Another task instance is already running. Exiting."
        exit
      else
        task_run_state.value = true
        task_run_state.save!
        puts "Running this instance."
      end
    end

    messages = []
    local_error = false

    systems = []
    services = []
    Service.paratransit_services.published.is_ecolane.order(:id).each do |service|
      if not service.booking_details[:external_id].blank? and
         not service.booking_details[:external_id].in? systems and
         not service.booking_details[:token].blank? and
         not service.agency.blank?
        systems << service.booking_details[:external_id]
        services << service
        puts "Preparing to sync System: #{service.booking_details[:external_id]}, Service: #{service.id} #{service.name}, Agency: #{service&.agency&.id}"
      end
    end

    puts "starting sync"
    Landmark.update_all(old: true)
    poi_processed_count = 0
    poi_with_no_city = 0
    poi_blank_name_count = 0
    poi_total_duplicate_count = 0

    new_poi_names_set = Set.new

    services.each do |service|
      local_error = false
      system = service.booking_details[:external_id]
      agency_id = service&.agency&.id
      service_id = service.id

      begin
        new_poi_hashes = service.booking_ambassador.get_pois
        if new_poi_hashes.nil?
          messages << "Error loading POIs for System: #{system}, service_id: #{service.id}, service_name: #{service.name}, service_agency_name: #{service&.agency&.name}. There is an issue with the service configuration. Please check the service configuration and try again."
          local_error = true
          puts messages.to_s
          break
        end

        puts "Processing #{new_poi_hashes.count} POIs for #{system}"
        new_poi_duplicate_count = 0
        new_poi_hashes_sorted = new_poi_hashes.sort_by { |h| h[:name].blank? ? 'ZZZZZ' : h[:name] }
        new_poi_hashes_sorted.each do |hash|
          poi_processed_count += 1
          puts "#{poi_processed_count} POIs processed, #{new_poi_duplicate_count} duplicates, #{poi_with_no_city} missing cities" if poi_processed_count % 1000 == 0

          new_poi = Landmark.new hash
          new_poi.old = false
          new_poi.agency_id = agency_id
          new_poi.service_id = service_id
          if new_poi.city.blank?
            puts 'CITYLESS POI, EXCLUDING FROM WAYPOINTS'
            puts hash.ai
            poi_with_no_city += 1
            next
          end

          next if new_poi.name =~ /do not use/i

          if new_poi.name.blank?
            new_poi.name = new_poi.auto_name
            poi_blank_name_count += 1
            new_poi.search_text = ''
          else
            new_poi.search_text = "#{new_poi.name} "
          end

          new_poi.search_text += "#{new_poi.auto_name}"
          if new_poi_names_set.add?(new_poi.search_text.strip.downcase).nil?
            new_poi_duplicate_count += 1
            puts "Duplicate found: #{new_poi.search_text}"
            next
          end

          new_poi.search_text += " #{new_poi.zip}"

          if !new_poi.save(validate: false)
            puts "Save failed for POI with errors #{new_poi.errors.full_messages}"
            puts "#{new_poi}"
          end
        end

      rescue Exception => e
        messages << "Error loading POIs for #{system}. #{e.message}. Backtrace: #{e.backtrace.join("\n")}"
        local_error = true
        puts messages.to_s
        break
      end

      unless local_error
        new_poi_count = new_poi_hashes.count
        messages << "Successfully loaded  #{new_poi_count} POIs with #{new_poi_duplicate_count} duplicates for #{system}."
        poi_total_duplicate_count += new_poi_duplicate_count
      end

    end

    unless local_error
      landmark_set_landmark_ids = LandmarkSetLandmark.all.pluck(:landmark_id)
      Landmark.is_old.where.not(id: landmark_set_landmark_ids).destroy_all
      Landmark.is_old.where(id: landmark_set_landmark_ids).update_all(old: false)
      new_poi_count = Landmark.count
      messages << "Successfully loaded #{new_poi_count} POIs"
      messages << "count of pois with duplicate names: #{poi_total_duplicate_count}"
      messages << "count of pois with no city: #{poi_with_no_city}"
      messages << "count of pois with initial blank name: #{poi_blank_name_count}"
      puts messages.to_s
    end

  ensure
    task_run_state.update(value: false) unless is_already_running

    if local_error
      Landmark.is_new.delete_all
      Landmark.is_old.update_all(old: false)
      ErrorMailer.ecolane_error_notification(messages).deliver_now
    end
  end

  desc "Update Waypoints with an incorrect township as the city to the correct city"
  task fix_townships_city: :environment do
    messages = []
    Trip::CORRECTED_CITIES_HASHES.each do |tp|
      puts "Updating waypoints for #{tp[:incorrect]}"
      wps = Waypoint.where(city: tp[:incorrect])
      incorrect_waypoints_length = wps.length
      wps.update_all(city: tp[:correct])
      messages << "Updated #{incorrect_waypoints_length} waypoints with city name of #{tp[:incorrect]} to new city name of #{tp[:correct]}"

      Waypoint.where("name like ?", "%#{tp[:incorrect]}%").map do |wp|
        puts "Updating waypoint name #{wp.name}"
        wp.name.gsub!(tp[:incorrect], tp[:correct])
        wp.save!
      end
    end
    puts messages.to_s
  end
end
