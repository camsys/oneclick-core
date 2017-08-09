module EmailHelper
  
  def duration_to_words(time_in_seconds)
    return "n/a" unless time_in_seconds

    time_in_seconds = time_in_seconds.to_i
    hours = time_in_seconds/3600
    minutes = (time_in_seconds - (hours * 3600))/60

    time_string = ''

    if hours > 0
      if hours > 1
        time_string << hours.to_s + " hours "
      else
        time_string << hours.to_s + " hour "
      end
    end

    if minutes > 0 
      time_string << minutes.to_s + " minute"
      time_string << "s" if minutes != 1
    end

    time_string
  end

  def exact_distance_to_words(dist_in_meters)
    return '' unless dist_in_meters

    # convert the meters to miles
    miles = dist_in_meters * 0.000621371
    if miles < 0.1
      dist_str = [(5280.0 * miles).round(0).to_s, "feet"].join(' ')
    else
      dist_str = [miles.round(2).to_s, "miles"].join(' ')
    end

    dist_str
  end

  def html_steps steps
      html = ""

      steps.each do |hash|
        html << "<p><b>"
        html << hash["relativeDirection"].humanize
        html << "</b> onto "
        html << hash["streetName"].to_s
        html << ", "
        html << exact_distance_to_words(hash["distance"] * 1.0)
        html << "</br></p>"
      end

      html << "</div>"
      return html.html_safe
    end

  # Returns a mode-specific icon
  def get_mode_icon mode

    case mode
    when "WALK"
      return "walk.png"
    when "CAR"
      return "auto.png"
    when "TRAM", "SUBWAY"
      return "subway.png"
    when "BUS"
      return "bus.png"
    when "BICYCLE"
      return "bicycle.png"
    else
      Rails.logger.info "#{mode} does not have a supported icon, defaulting to bus.png"
      return "bus.png"
    end

  end

    # Returns a mode-specific icon
  def short_description leg

    case leg['mode']
    when "WALK"
      return "Walk to #{leg['to']['name']}"
    when "BICYCLE"
      return "Bike to #{leg['to']['name']}"
    when "CAR"
      return "Drive to #{leg['to']['name']}"
    when "TRAM", "SUBWAY"
      return "#{leg['agencyName']} #{leg['route']} to #{leg['to']['name']}"
    when "BUS"
      return "#{leg['agencyName']} #{leg['route']} to #{leg['to']['name']}"
    else 
      Rails.logger.info "#{leg['mode']} does not have a supported short description, defaulting to bus description"
      return "#{leg['agencyName']} #{leg['route']} to #{leg['to']['name']}"
    end

  end

    # Returns a mode-specific icon
  def get_mode_partial itinerary

    case itinerary.trip_type
    when "uber", "taxi"
      return "taxi_tnc_details"
    else
      return "static_details"
    end

  end
  
end