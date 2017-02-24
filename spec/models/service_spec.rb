require 'rails_helper'

RSpec.describe Service, type: :model do
  it { should respond_to :name, :logo, :type, :email, :phone, :url, :gtfs_agency_id }
  it { should have_many(:itineraries) }

  let(:service) { create(:service)}
  let(:transit) { create(:transit)}
  let(:paratransit) { create(:paratransit)}

  it 'should have a logo with a thumbnail version' do
    expect(service.logo_url).to be
    expect(service.logo.content_type[0..4]).to eq("image")
    expect(service.logo.thumb).to be
  end

  it 'transit service should be a Transit and have appropriate attributes' do
    expect(transit).to be
    expect(transit).to be_a(Transit)
    expect(transit.gtfs_agency_id).to be
  end

  it 'paratransit service should be a Paratransit and have appropriate attributes' do
    expect(paratransit).to be
    expect(paratransit).to be_a(Paratransit)
  end

end
