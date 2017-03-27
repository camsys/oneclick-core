class Paratransit < Service

  ### INSTANCE METHODS ###

  # Build associated geographies
  def build_geographies
    build_start_or_end_area unless start_or_end_area
    build_trip_within_area unless trip_within_area
  end

end


# Alias ParatransitService to Paratransit
ParatransitService = Paratransit
