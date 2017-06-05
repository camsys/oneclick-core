require 'rails_helper'

RSpec.describe Api::V1::UserSerializer, type: :serializer do
  let!(:traveler) { FactoryGirl.create :user }
  let!(:traveler_serializer) { Api::V1::UserSerializer.new(traveler)}
  let!(:traveler_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(traveler_serializer).to_json) }

  let!(:english_traveler) { FactoryGirl.create(:english_speaker, :eligible, :not_a_veteran, :needs_accommodation) }
  let!(:eng_traveler_serializer) { Api::V1::UserSerializer.new(english_traveler)}
  let!(:eng_traveler_serialization) { JSON.parse(ActiveModelSerializers::Adapter.create(eng_traveler_serializer).to_json) }


  it "faithfully serializes user's basic attributes" do
    expect(traveler_serialization["email"]).to eq(traveler.email)
    expect(traveler_serialization["first_name"]).to eq(traveler.first_name)
    expect(traveler_serialization["last_name"]).to eq(traveler.last_name)


    # attributes  :email, :first_name, :last_name,
    #             :lang, :characteristics, :accommodations,
    #             :preferred_modes
  end

  it "serializes traveler's preferred language and modes" do
    expect(eng_traveler_serialization["lang"]).to eq(english_traveler.preferred_locale.name)
    expect(eng_traveler_serialization["preferred_modes"].to_a).to eq(english_traveler.preferred_trip_types)
  end

  it 'returns the eligibilities_hash' do
  	expect(eng_traveler_serialization["characteristics"][0]["code"]).to eq('over_65')
    expect(eng_traveler_serialization["characteristics"][0]["name"]).to eq('missing key eligibility_over_65_name')
    expect(eng_traveler_serialization["characteristics"][0]["note"]).to eq('missing key eligibility_over_65_note')
    expect(eng_traveler_serialization["characteristics"][0]["question"]).to eq('missing key eligibility_over_65_question')
  end

  it 'returns the accommodations_hash' do
  	expect(eng_traveler_serialization["accommodations"][0]["code"]).to eq('wheelchair')
  	expect(eng_traveler_serialization["accommodations"][0]["name"]).to eq('missing key accommodation_wheelchair_name')
    expect(eng_traveler_serialization["accommodations"][0]["note"]).to eq('missing key accommodation_wheelchair_note')
    expect(eng_traveler_serialization["accommodations"][0]["question"]).to eq('missing key accommodation_wheelchair_question')
    expect(eng_traveler_serialization["accommodations"][0]["value"]).to eq true
  end
end
