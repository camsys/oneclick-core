class Taxi < Service
  # Build associated geographies
  def build_geographies
    build_trip_within_area unless trip_within_area
  end

  # Returns true if trip falls within service coverage areas.
  def available_by_geography_for?(trip)
    available_by_trip_within_area_for?(trip)
  end

  # Returns true if user meets all accommodation requirements
  def available_for_user?(user)
    accommodates?(user)
  end
end

# Alias TaxiService to Taxi
TaxiService = Taxi

