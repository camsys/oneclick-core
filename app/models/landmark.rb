class Landmark < ApplicationRecord
  
  include GooglePlace 

  serialize :types 

  # Search over all landmarks by query string
  def self.get_by_query_str(query_str, limit, has_address=false)
    rel = Landmark.arel_table[:name].lower().matches(query_str)
    landmarks = Landmark.where(rel).limit(limit)
    landmarks
  end

end
