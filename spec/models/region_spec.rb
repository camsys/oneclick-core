require 'rails_helper'

RSpec.describe Region, type: :model do

  let!(:geographies) { [
    County.find_by(name: "Essex"),
    City.find_by(name: "Boston"),
    Zipcode.find_by(name: "02139")
  ] }
  let!(:region) { create(:combined_region) }
  let(:waypoint) { create(:waypoint_02139) }
  let(:way_out_point) { create(:way_out_point) }
  let(:trip) { create(:trip, origin: waypoint, destination: way_out_point) }
  let(:reverse_trip) { create(:trip, origin: way_out_point, destination: waypoint) }

  it { should respond_to :recipe, :geom }
  it { should have_many(:fare_zones) }
  it { should have_many(:fare_zone_services).through(:fare_zones) }

  it 'should have a multi_polygon for a geom value' do
    expect(region.geom).to be_a RGeo::Geos::CAPIMultiPolygonImpl
  end

  it 'contains all geometries from its recipe' do
    expect(geographies.all? do |g|
      g.geom.within?(region.geom)
    end).to be true
  end

  it 'has a contains? helper function that works on places' do
    expect(region.contains?(waypoint)).to be true
    expect(region.contains?(way_out_point)).to be false
  end

  it 'can be scoped to trip origin and destination' do
    expect(Region.origin_for(trip).include?(region)).to be true
    expect(Region.destination_for(trip).include?(region)).to be false
    expect(Region.origin_for(reverse_trip).include?(region)).to be false
    expect(Region.destination_for(reverse_trip).include?(region)).to be true
  end
end
