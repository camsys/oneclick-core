require 'rails_helper'

RSpec.describe Service, type: :model do
  it { should respond_to :name, :logo, :type, :email, :phone, :url, :gtfs_agency_id }
  it { should have_many(:itineraries) }
  it { should have_and_belong_to_many :accommodations }
  it { should have_and_belong_to_many :eligibilities }

  let(:service) { create(:service)}
  let(:transit) { create(:transit_service)}
  let(:paratransit) { create(:paratransit_service)}
  let(:user) { create(:user) }

  # Creating 'seed' data for this spec file
  let!(:jacuzzi) { FactoryGirl.create :jacuzzi }
  let!(:wheelchair) { FactoryGirl.create :wheelchair }
  let!(:eligibility) { FactoryGirl.create :eligibility }

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
    # Make the paratransit service accommodating
    paratransit.accommodations += [jacuzzi, wheelchair]

    # The user needs no accommodations
    expect(paratransit.accommodates?(user)).to be true

    # Make the user need accommodations
    user.accommodations += [jacuzzi, wheelchair]

    # The service should still be accommodating
    expect(paratransit.accommodates?(user)).to be true
  end

  it 'should be unavailable to users if it lacks a necessary accommodation' do
    # The user needs no accommodations, this service should be good
    expect(paratransit.accommodates?(user)).to be true

    # Make the user need accommodations
    user.accommodations += [jacuzzi, wheelchair]

    # This service does not provide the above accommodations
    expect(paratransit.accommodates?(user)).to be false
  end

  it 'should be available to users that meet all eligibility requirements' do
    # Make the paratransit service strict
    paratransit.eligibilities << eligibility

    # Make the user eligible
    ue = UserEligibility.where(user: user, eligibility: eligibility).first_or_create
    ue.value = true
    ue.save

    # The user should be eligible
    expect(paratransit.accepts_eligibility_of?(user)).to be true
  end

  it 'should be unavailable to users that do not meet all eligibility requirements' do
    # Make the paratransit service strict
    paratransit.eligibilities << eligibility

    # The user should not be eligible
    expect(paratransit.accepts_eligibility_of?(user)).to be false
  end

end
