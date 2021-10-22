namespace :ecolane do

  desc "Update Ecolane POIs"
  task :update_pois => :environment do

    messages = []
    global_error = false
    local_error = false

    #Ecolane POIs are broken down by system.  First, get a list of all the unique Ecolane Systems
    systems = []
    services  = []
    Service.paratransit_services.published.is_ecolane.each do |service|
      if not service.booking_details[:external_id].blank? and not service.booking_details[:external_id].in? systems and not service.booking_details[:token].blank?
        systems << service.booking_details[:external_id]
        services << service
      end
    end

    # Get the current POIs and mark them as old
    Landmark.update_all(old: true)
    poi_with_no_city = 0
    services.each do |service|
      local_error = false
      system = service.booking_details[:external_id]

      begin
        # Get a Hash of new POIs from Ecolane
        new_poi_hashes = service.booking_ambassador.get_pois

        if new_poi_hashes.nil?
          #If anything goes wrong, delete the new pois and reinstate the old_pois
          Landmark.is_new.delete_all
          Landmark.is_old.update_all(old: false)
          messages << "Error loading POIs for System: #{system}, service_id: #{service.id}. Unable to retrieve POIs"
          global_error = true
          local_error = true
          next
        end

        # Import named pois before unnamed locations
        new_poi_hashes_sorted = new_poi_hashes.sort_by { |h| h[:name].blank? ? 'ZZZZZ' : h[:name] }
        new_poi_hashes_sorted.each do |hash|

          if Landmark.is_new.where('lower(name) = ?', hash[:name].downcase).count > 0
            puts 'DUPLICATE '
            puts hash.ai
            next
          end

          new_poi = Landmark.new hash
          new_poi.old = false
          # All POIs need a name, if Ecolane doesn't define one, then name it after the Address
          # POIS should also have a city, if the POI doesn't have a city then skip it and log it in the console
          if new_poi.name.blank? or new_poi.name.downcase == 'home'
            if new_poi.city == nil || new_poi.city == ""
              puts 'CITYLESS POI, EXCLUDING FROM WAYPOINTS'
              puts hash.ai
              poi_with_no_city += 1
              next
            end
            new_poi.name = [new_poi.street_number, new_poi.route, new_poi.city].join(" ")
          end
          new_poi.save
        end

      rescue Exception => e
        #If anything goes wrong, delete the new pois and reinstate the old_pois
        Landmark.is_new.delete_all
        Landmark.is_old.update_all(old: false)
        messages << "Error loading POIs for #{system}. #{e.message}."
        global_error = true
        local_error = true
        # Log if errors happen
        puts messages.to_s
      end

      unless local_error
        #If we made it this far, then we have a new set of POIs and we can delete the old ones.
        new_poi_count = new_poi_hashes.count
        messages << "Successfully loaded  #{new_poi_count} POIs for #{system}."
      end

    end

    unless local_error
      #If we made it this far, then we have a new set of POIs and we can delete the old ones.
      Landmark.is_old.delete_all
      new_poi_count = Landmark.count
      messages << "Successfully loaded  #{new_poi_count} POIs"
      messages << "count of pois with no city: #{poi_with_no_city}"
      puts messages.to_s
    end

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