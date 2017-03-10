require 'rails_helper'

RSpec.describe Region, type: :model do

  # Create Geographies so that region builds properly.
  before(:each) do
    create(:county)
    create(:city)
    create(:zipcode)
  end
  let(:geographies) { [ County.last, City.last, Zipcode.last ] }
  let(:region) { create(:region) }

  it { should respond_to :recipe, :geom }

  it 'should have a multi_polygon for a geom value' do
    expect(region.geom).to be_a RGeo::Geos::CAPIMultiPolygonImpl
  end

  it 'contains all geometries from its recipe' do
    expect(geographies.all? {|g| g.geom.within?(region.geom)}).to be true
  end
end
