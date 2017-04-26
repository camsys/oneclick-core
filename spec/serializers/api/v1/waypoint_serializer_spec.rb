require 'rails_helper'

RSpec.describe Api::V1::WaypointSerializer, type: :serializer do
  let(:waypoint) { create(:waypoint)}
  let(:waypoint_serializer) { Api::V1::WaypointSerializer.new(waypoint)}
  let(:waypoint_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(waypoint_serializer).to_json) }

  it 'faithfully serializes waypoints' do
    expect(waypoint_serialization["id"]).to eq(waypoint.id)
    expect(waypoint_serialization["name"]).to eq(waypoint.name)

    expect(waypoint_serialization["address_components"][0]["long_name"]).to eq(waypoint.street_number)
    expect(waypoint_serialization["address_components"][1]["long_name"]).to eq(waypoint.route)
    expect(waypoint_serialization["address_components"][2]["long_name"]).to eq(waypoint.city)
    expect(waypoint_serialization["address_components"][3]["long_name"]).to eq(waypoint.zip)
    expect(waypoint_serialization["address_components"][4]["long_name"]).to eq(waypoint.state)

    expect(waypoint_serialization["geometry"]["location"]["lat"]).to eq(waypoint.lat)
    expect(waypoint_serialization["geometry"]["location"]["lng"]).to eq(waypoint.lng)

    expect(waypoint_serialization["formatted_address"]).to eq(
      "#{waypoint.street_number} #{waypoint.route}, #{waypoint.city}, #{waypoint.state} #{waypoint.zip}"
    )

  end

end
