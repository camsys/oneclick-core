class Itinerary < ApplicationRecord
  belongs_to :trip
  belongs_to :service

  serialize :legs

  # Duration virtual attribute sums all trip_time attributes
  def duration
    walk_time + transit_time #+ wait_time
  end

end
