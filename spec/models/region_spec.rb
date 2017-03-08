require 'rails_helper'

RSpec.describe Region, type: :model do
  it { should respond_to :recipe, :geom }
  let(:region) { create(:region) }

  it 'should have a multi_polygon for a geom value' do
    expect(region.geom).to be_a RGeo::Geos::CAPIMultiPolygonImpl
  end
end
