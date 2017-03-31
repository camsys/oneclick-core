require 'rails_helper'

RSpec.describe Region, type: :model do

  let(:geographies) { [
    County.find_by(name: "Essex", state: "MA"),
    City.find_by(name: "Boston", state: "MA"),
    Zipcode.find_by(name: "02139")
  ] }
  let(:region) { create(:combined_region) }
  let(:waypoint) { create(:waypoint_1) }
  let(:way_out_point) { create(:way_out_point) }

  it { should respond_to :recipe, :geom }

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
end
