require 'rails_helper'

RSpec.describe Api::V1::TripSerializer, type: :serializer do
  let(:trip) { create(:trip_with_paratransit_itins)}
  let(:trip_serializer) { Api::V1::TripSerializer.new(trip)}
  let(:trip_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(trip_serializer).to_json) }

  it 'faithfully serializes trips' do
    expect(trip_serialization["id"]).to eq(trip.id)
    expect(trip_serialization["trip_time"].to_datetime).to eq(trip.trip_time)
    expect(trip_serialization["arrive_by"]).to eq(trip.arrive_by)
    expect(trip_serialization["user_id"]).to eq(trip.user_id)
    expect(trip_serialization["origin"]).to be
    expect(trip_serialization["destination"]).to be
    expect(trip_serialization["itineraries"].count).to be > 0
    expect(trip_serialization["purposes"]).to eq([{"name"=>"missing key purpose_medical_name", "code"=>"medical"}])
  end

end
