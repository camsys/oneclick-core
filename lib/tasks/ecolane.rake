namespace :ecolane do

  desc "Update Ecolane POIs"
  task :update_pois => :environment do
    start_time = Time.now

    # Check to see if another instance is already running
    is_already_running = false
    task_run_state = Config.find_or_create_by key: 'ecolane_task_is_running'
    task_run_state.with_lock do
      task_run_state.reload
      is_already_running = task_run_state.value
      # Make sure this isn't an old value that didn't get cleaned up
      if is_already_running && task_run_state.updated_at > (DateTime.now - 1.day)
        puts "Another task instance is already running. Exiting."
        exit
      else
        task_run_state.value = true
        task_run_state.save!
        puts "Running this instance."
      end
    end
    
    summary_messages = []
    error_messages = []
    local_error = false
    domain = ENV['MAIL_HOST'] || 'unknown domain'

    # Ecolane POIs are broken down by system. First, get a list of all the unique Ecolane Systems.
    # Order from oldest to newest.
    systems = []
    services_by_system = Hash.new { |hash, key| hash[key] = [] }

    Service.paratransit_services.published.is_ecolane.order(:id).each do |service|
      if not service.booking_details[:external_id].blank? and
        not service.booking_details[:token].blank? and
        not service.agency.blank?
        systems << service.booking_details[:external_id] unless systems.include?(service.booking_details[:external_id])
        services_by_system[service.booking_details[:external_id]] << service
        puts "Preparing to sync System: #{service.booking_details[:external_id]}, Service: #{service.id} #{service.name}, Agency: #{service&.agency&.id}"
      end
    end

    puts "starting sync"
    # Get the current POIs and mark them as old
    Landmark.update_all(old: true)
    poi_processed_count = 0
    poi_with_no_city = 0
    poi_blank_name_count = 0
    poi_total_duplicate_count = 0
    total_pois_loaded = 0
    
    new_poi_names_set = Set.new

    systems.each do |system|
      services = services_by_system[system]
      agencies = services.map(&:agency).uniq
      services.each do |service|
        puts "Processing system: #{system} with service: #{service.name}"  # Log all services for the system
      end
      local_error = false
      system_start_time = Time.now

      begin
        # Get a Hash of new POIs from Ecolane
        # NOTE: INCLUDES THE SERVICE'S AGENCY
        new_poi_hashes = services.first.booking_ambassador.get_pois
        if new_poi_hashes.nil?
          # If anything goes wrong the new pois will be deleted and the old reinstated
          error_messages << "Error loading POIs for System: #{system}. Unable to retrieve POIs"
          local_error = true
          puts error_messages.to_s
          break
        end

        puts "Processing #{new_poi_hashes.count} POIs for #{system}"
        new_poi_duplicate_count = 0
        # Import named pois before unnamed locations
        new_poi_hashes_sorted = new_poi_hashes.sort_by { |h| h[:name].blank? ? 'ZZZZZ' : h[:name] }
        new_poi_hashes_sorted.each do |hash|
          poi_processed_count += 1
          puts "#{poi_processed_count} POIs processed, #{new_poi_duplicate_count} duplicates, #{poi_with_no_city} missing cities" if poi_processed_count % 100 == 0
          
          new_poi = Landmark.new hash
          new_poi.old = false
          # POIS should also have a city, if the POI doesn't have a city then skip it and log it in the console
          if new_poi.city.blank?
            puts 'CITYLESS POI, EXCLUDING FROM WAYPOINTS'
            puts hash.ai
            poi_with_no_city += 1
            next
          end

          # Skip POIs whose names contain "do not use" case insensitive
          next if new_poi.name =~ /do not use/i
          
          # All POIs need a name, if Ecolane doesn't define one, then name it after the Address
          if new_poi.name.blank?
            # or new_poi.name.downcase == 'home'
            new_poi.name = new_poi.auto_name
            poi_blank_name_count += 1
            new_poi.search_text = ''
          else
            new_poi.search_text = "#{new_poi.name} "
          end

          # Use the name + address to determine duplicates
          new_poi.search_text += "#{new_poi.auto_name}"
          if new_poi_names_set.add?(new_poi.search_text.strip.downcase).nil?
            new_poi_duplicate_count += 1
            puts "Duplicate found: #{new_poi.search_text}"
            next
          end

          new_poi.search_text += " #{new_poi.zip}"

          # HACK: Because of FMRPA-153 we need to support duplicate names.
          # Rather than change the model validation for all of 1-Click, just override it here for FMR.
          if !new_poi.save(validate: false)
            puts "Save failed for POI with errors #{new_poi.errors.full_messages}"
            puts "#{new_poi}"
          else
            # Associate the new POI with all relevant services and agencies
            services.each do |svc|
              new_poi.services << svc
            end
            agencies.each do |agency|
              new_poi.agencies << agency
            end
          end
        end

      rescue Exception => e
        # If anything goes wrong....
        error_messages << "Error loading POIs for System: #{system}. #{e.message}. (Domain: #{domain})"
        local_error = true
        # Log if errors happen
        puts error_messages.to_s
        break
      end

      system_end_time = Time.now
      unless local_error
        # If we made it this far, then we have a new set of POIs and we can delete the old ones.
        new_poi_count = new_poi_hashes.count
        total_pois_loaded += new_poi_count
        service_names = services.map(&:name).join(", ")
        summary_messages << "<strong>System:</strong> #{system}<br>"
        summary_messages << "<strong>Services using this system:</strong> #{service_names}<br>"
        summary_messages << "POIs Loaded: #{new_poi_count}<br>"
        summary_messages << "Duplicates: #{new_poi_duplicate_count}<br>"
        summary_messages << "Processed in: #{((system_end_time - system_start_time) / 60).round(2)} minutes.<br><br>"
        poi_total_duplicate_count += new_poi_duplicate_count
      end
    end

    unless local_error
      # If we made it this far, then we have a new set of POIs and we can delete the old ones.
      # Exclude any in use.
      # TODO: For OCC-957, this needs to be updated to match and update POIs in use using mobile API location id.
      landmark_set_landmark_ids = LandmarkSetLandmark.all.pluck(:landmark_id)
      Landmark.is_old.where.not(id: landmark_set_landmark_ids).destroy_all
      Landmark.is_old.where(id: landmark_set_landmark_ids).update_all(old: false)
      new_poi_count = Landmark.count
      summary_messages << "<strong>Summary:</strong><br>"
      summary_messages << "Total POIs Loaded: #{new_poi_count}<br>"
      summary_messages << "Total Duplicates: #{poi_total_duplicate_count}<br>"
      summary_messages << "Total POIs with no city: #{poi_with_no_city}<br>"
      summary_messages << "Total POIs with initial blank name: #{poi_blank_name_count}<br>"
    end

  ensure
    end_time = Time.now
    total_time = end_time - start_time
    total_hours = (total_time / 3600).to_i
    total_minutes = ((total_time % 3600) / 60).round(2)
    total_time_str = "#{total_hours} hours and #{total_minutes} minutes"

    task_run_state.update(value: false) unless is_already_running

    if error_messages.any?
      error_messages << "<strong>Total time spent:</strong> #{total_time_str}."
      ErrorMailer.ecolane_error_notification(error_messages).deliver_now
    end

    summary_messages << "<strong>Total time spent:</strong> #{total_time_str}."
    DeveloperMailer.ecolane_summary_notification(summary_messages).deliver_now
  end #update_pois

  # [PAMF-751] NOTE: This is all hard-coded, ideally there's be a better way to do this
  desc "Update Waypoints with an incorrect township as the city to the correct city"
  task fix_townships_city: :environment do
    messages = []
    Trip::CORRECTED_CITIES_HASHES.each do |tp|
      puts "Updating waypoints for #{tp[:incorrect]}"
      wps = Waypoint.where(city: tp[:incorrect])
      incorrect_waypoints_length = wps.length
      wps.update_all(city: tp[:correct])
      messages << "Updated #{incorrect_waypoints_length} waypoints with city name of #{tp[:incorrect]} to new city name of #{tp[:correct]}"

      # Correct the Waypoint name if it includes the incorrect township.
      Waypoint.where("name like ?", "%#{tp[:incorrect]}%").map do |wp|
        puts "Updating waypoint name #{wp.name}"
        wp.name.gsub!(tp[:incorrect], tp[:correct])
        wp.save!
      end
    end
    puts messages.to_s
  end

end #ecolane
