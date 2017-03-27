class Taxi < Service

  ### INSTANCE METHODS ###

  # Build associated geographies
  def build_geographies
    build_trip_within_area unless trip_within_area
  end

end

# Alias TaxiService to Taxi
TaxiService = Taxi
