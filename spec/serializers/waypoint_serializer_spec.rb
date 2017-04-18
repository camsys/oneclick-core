require 'rails_helper'

RSpec.describe Api::V1::WaypointSerializer, type: :serializer do
  let(:waypoint) { create(:waypoint)}
  let(:waypoint_serializer) { Api::V1::WaypointSerializer.new(waypoint)}
  let(:waypoint_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(waypoint_serializer).to_json) }

  it 'faithfully serializes waypoints' do
    expect(waypoint_serialization["name"]).to eq(waypoint.name)
    expect(waypoint_serialization["street_number"]).to eq(waypoint.street_number)
    expect(waypoint_serialization["route"]).to eq(waypoint.route)
    expect(waypoint_serialization["city"]).to eq(waypoint.city)
    expect(waypoint_serialization["state"]).to eq(waypoint.state)
    expect(waypoint_serialization["zip"]).to eq(waypoint.zip)
    expect(waypoint_serialization["lat"].to_f).to eq(waypoint.lat)
    expect(waypoint_serialization["lng"].to_f).to eq(waypoint.lng)
  end

end
