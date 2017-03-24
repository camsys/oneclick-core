class Paratransit < Service

  ### INSTANCE METHODS ###

  # Build associated geographies
  def build_geographies
    build_start_or_end_area unless start_or_end_area
    build_trip_within_area unless trip_within_area
  end

  # Returns true if trip falls within service coverage areas.
  def available_by_geography_for?(trip)
    available_by_start_or_end_area_for?(trip) &&
    available_by_trip_within_area_for?(trip)
  end

  # Returns true if user meets all accoomodation and eligibility requirements
  def available_for_user?(user)
    accommodates?(user) &&
    accepts_eligibility_of?(user)
  end

  # Returns true if trip time falls within service's schedules, or
  # if no schedules have been set for this service
  def available_by_schedule_for?(trip)
    schedules.empty? || available_by_schedule_for_trip_time?(trip)
  end

end


# Alias ParatransitService to Paratransit
ParatransitService = Paratransit
