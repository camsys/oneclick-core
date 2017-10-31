require 'rails_helper'

RSpec.describe Api::V2::ItinerarySerializer, type: :serializer do
  
  let(:transit_itinerary) { create(:transit_itinerary) }
  let(:paratransit_itinerary) { create(:paratransit_itinerary) }
  let(:transit_serialization) { Api::V2::ItinerarySerializer.new(transit_itinerary).to_h }
  let(:paratransit_serialization) { Api::V2::ItinerarySerializer.new(paratransit_itinerary).to_h }

  # Basic serialized attributes
  let(:attributes) do
    [
      :trip_type,
      :cost,
      :walk_time,
      :transit_time,
      :walk_distance,
      :wait_time,
      :legs,
      :duration
    ]
  end
  
  it "faithfully serializes a transit itinerary with legs" do
    attributes.each do |attr|
      expect(transit_serialization[attr]).to eq(transit_itinerary.send(attr))
    end
  end
  
  it "faithfully serializes a paratransit itinerary with associated service" do
    attributes.each do |attr|
      expect(paratransit_serialization[attr]).to eq(paratransit_itinerary.send(attr))
    end
    expect(paratransit_serialization[:service]).to be_a Service
  end

end
