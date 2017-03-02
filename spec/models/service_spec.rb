require 'rails_helper'

RSpec.describe Service, type: :model do
  it { should respond_to :name, :logo, :type, :email, :phone, :url, :gtfs_agency_id }
  it { should have_many(:itineraries) }
  it { should have_and_belong_to_many :accommodations }

  let(:service) { create(:service)}
  let(:transit) { create(:transit_service)}
  let(:paratransit) { create(:paratransit_service)}
  let(:accommodating_paratransit) { create(:paratransit_service, :accommodating)}
  let(:user_without_needs) { create(:user) }
  let(:user_needs_accommodation) { create(:user, :needs_accommodation) }

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

  it 'should be available to users if it has all necessary accommodations' do
    expect(accommodating_paratransit.accommodates?(user_without_needs)).to be true
    expect(accommodating_paratransit.accommodates?(user_needs_accommodation)).to be true
  end

  it 'should be unavailable to users if it lacks a necessary accommodation' do
    expect(paratransit.accommodates?(user_without_needs)).to be true
    expect(paratransit.accommodates?(user_needs_accommodation)).to be false
  end

end
