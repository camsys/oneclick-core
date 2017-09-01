require 'rails_helper'

RSpec.describe ServiceSerializer, type: :serializer do
  let(:transit_service) { create(:transit_service)}
  let(:transit_serializer) { ServiceSerializer.new(transit_service)}
  let(:transit_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(transit_serializer).to_json) }

  let(:paratransit_service) { create(:paratransit_service)}
  let(:paratransit_serializer) { ServiceSerializer.new(paratransit_service)}
  let(:paratransit_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(paratransit_serializer).to_json) }

  it 'faithfully serializes transit services' do
    expect(transit_serialization["id"]).to eq(transit_service.id)
    expect(transit_serialization["name"]).to eq(transit_service.name)
    expect(transit_serialization["type"]).to eq(transit_service.type)
    expect(transit_serialization["url"]).to eq(transit_service.url)
    expect(transit_serialization["email"]).to eq(transit_service.email)
    expect(transit_serialization["phone"]).to eq(transit_service.formatted_phone)
  end

  it 'faithfully serializes paratransit services' do
    expect(paratransit_serialization["id"]).to eq(paratransit_service.id)
    expect(paratransit_serialization["name"]).to eq(paratransit_service.name)
    expect(paratransit_serialization["type"]).to eq(paratransit_service.type)
    expect(paratransit_serialization["url"]).to eq(paratransit_service.url)
    expect(paratransit_serialization["email"]).to eq(paratransit_service.email)
    expect(paratransit_serialization["phone"]).to eq(paratransit_service.formatted_phone)
  end

end
