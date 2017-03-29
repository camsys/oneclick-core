class Paratransit < Service
  accepts_nested_attributes_for :start_or_end_area, :trip_within_area
  accepts_nested_attributes_for :schedules, reject_if: :reject_schedule?, allow_destroy: true

  ### INSTANCE METHODS ###

  # Build associated geographies
  def build_geographies
    build_start_or_end_area unless start_or_end_area
    build_trip_within_area unless trip_within_area
  end

end


# Alias ParatransitService to Paratransit
ParatransitService = Paratransit
