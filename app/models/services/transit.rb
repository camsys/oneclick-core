class Transit < Service

  # Build associated geographies
  def build_geographies
    nil
  end

  # Returns true if trip falls within service coverage areas.
  def available_by_geography_for?(trip)
    true
  end

  # Returns true if user meets all accoomodation and eligibility requirements
  def available_for_user?(user)
    true
  end

end


# Alias TransitService to Transit
TransitService = Transit
