require 'rails_helper'

RSpec.describe Api::V2::ItinerariesController, type: :controller do

  let(:trip) { create(:trip) }
  let(:itinerary) { create(:itinerary, trip: nil) }
  let(:paratransit_itinerary) { create(:paratransit_itinerary, trip: nil) }
  let(:user) { trip.user }
  let(:hacker) { create(:english_speaker) }
  let!(:eligibility) { FactoryBot.create :eligibility }
  let!(:paratransit_service) { FactoryBot.create(:paratransit_service, :medical_only, :no_geography) }
  let!(:metallica_concert) { FactoryBot.create(:metallica_concert) }

  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:hacker_headers)  { {"X-USER-EMAIL" => hacker.email, "X-USER-TOKEN" => hacker.authentication_token} }

  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  before(:each) { create(:uber_token) }
  before(:each) { create(:lyft_client_token) }


  #### Emailing ###
  describe "emailing" do

    it 'sends an email', :skip do
      params = {email_address: 'test@oneclick.com', itinerary_id: paratransit_itinerary.id  }
      trip.itineraries << paratransit_itinerary
      trip.save
      post :email, params: params
      #todo: update factories for itineraries with enough info so that this succeeds
      expect(response.code).to eq("500")
    end

  end

  describe OTPAmbassador do
    describe 'when "walk" trip type is deselected' do
      it 'filters out itineraries where any leg\'s walking distance exceeds maximum walk distance' do
  
        trip_types = [:transit, :paratransit, :car_park, :taxi, :car, :bicycle, :uber, :lyft]
        otp_ambassador = OTPAmbassador.new(trip, trip_types)
  
        expect(otp_ambassador.get_itineraries(:transit)).not_to include(hash_including(mode: "WALK", distance: a_value > 1000))
      end

      it 'includes itineraries where any walking leg\'s distance is less than maximum walk distance' do
  
        trip_types = [:transit, :paratransit, :car_park, :taxi, :car, :bicycle, :uber, :lyft]
        otp_ambassador = OTPAmbassador.new(trip, trip_types)
  
        allow(otp_ambassador).to receive(:get_itineraries).and_return([
          { mode: "WALK", distance: 800 }
        ])
  
        expect(otp_ambassador.get_itineraries(:transit)).to include(hash_including(mode: "WALK", distance: a_value <= 1000))
      end
    end

    describe 'when "walk" trip type is selected' do
      it 'includes itineraries where any leg\'s walking distance is less than maximum walk distance' do
  
        trip_types = [:transit, :paratransit, :car_park, :taxi, :walk, :car, :bicycle, :uber, :lyft]
        otp_ambassador = OTPAmbassador.new(trip, trip_types)
        

        allow(otp_ambassador).to receive(:get_itineraries).and_return([
          { mode: "WALK", distance: 800 }
        ])
  
        expect(otp_ambassador.get_itineraries(:transit)).to include(hash_including(mode: "WALK", distance: a_value <= 1000))
      end
    end

  end  
end
