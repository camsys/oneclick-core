class Lyft < Service
  accepts_nested_attributes_for :trip_within_area

  ### INSTANCE METHODS ###

  # Build associated geographies
  def build_geographies
    build_trip_within_area unless trip_within_area
  end

end

# Alias UberService to Uber
LyftService = Lyft
