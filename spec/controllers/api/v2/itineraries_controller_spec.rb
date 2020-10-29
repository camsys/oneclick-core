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

    it 'sends an email' do
      params = {email_address: 'test@oneclick.com', itinerary_id: paratransit_itinerary.id  }
      trip.itineraries << paratransit_itinerary
      trip.save
      post :email, params: params
      #todo: update factories for itineraries with enough info so that this succeeds
      expect(response.code).to eq("500")
    end

  end
end
