require 'rails_helper'

RSpec.describe ServiceSerializer, type: :serializer do
  let(:transit_service) { create(:transit)}
  let(:transit_serializer) { ServiceSerializer.new(transit_service)}
  let(:transit_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(transit_serializer).to_json) }

  let(:paratransit_service) { create(:paratransit)}
  let(:paratransit_serializer) { ServiceSerializer.new(paratransit_service)}
  let(:paratransit_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(paratransit_serializer).to_json) }

  it 'faithfully serializes transit services' do
    expect(transit_serialization["id"]).to eq(transit_itinerary.id)
    expect(transit_serialization["cost"]).to eq(transit_itinerary.cost)
    expect(transit_serialization["walk_time"]).to eq(transit_itinerary.walk_time)
    expect(transit_serialization["transit_time"]).to eq(transit_itinerary.transit_time)
    expect(transit_serialization["start_time"].to_datetime).to eq(transit_itinerary.start_time)
    expect(transit_serialization["end_time"].to_datetime).to eq(transit_itinerary.end_time)
    expect(transit_serialization["legs"]).to eq(transit_itinerary.legs)
  end

  it 'faithfully serializes paratransit services' do
    expect(transit_serialization["id"]).to eq(transit_itinerary.id)
    expect(transit_serialization["cost"]).to eq(transit_itinerary.cost)
    expect(transit_serialization["walk_time"]).to eq(transit_itinerary.walk_time)
    expect(transit_serialization["transit_time"]).to eq(transit_itinerary.transit_time)
    expect(transit_serialization["start_time"].to_datetime).to eq(transit_itinerary.start_time)
    expect(transit_serialization["end_time"].to_datetime).to eq(transit_itinerary.end_time)
    expect(transit_serialization["legs"]).to eq(transit_itinerary.legs)
  end

end
