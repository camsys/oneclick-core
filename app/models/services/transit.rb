class Transit < Service

  ### INSTANCE METHODS ###

  # Build associated geographies
  def build_geographies
    nil
  end

end


# Alias TransitService to Transit
TransitService = Transit
