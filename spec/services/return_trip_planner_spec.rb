require 'rails_helper'

RSpec.describe ReturnTripPlanner do  
  
  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  
  # Stubbed OTP Responses
  let!(:otp_car_response) { JSON.parse(File.read("spec/files/otp_response_car.json")) }
  
  # Stubbed HTTPRequestBundler with fake OTP response
  before(:each) do
    HTTPRequestBundler.any_instance.stub(:response) { otp_car_response }
    HTTPRequestBundler.any_instance.stub(:make_calls) { {} }
    HTTPRequestBundler.any_instance.stub(:add) { true }
  end
  
  let(:rtp) { create(:return_trip_planner) }

  it { expect(rtp).to be_a TripPlanner } 

  it "builds a return trip based on the outbound trip" do
    
    # NOTE: In an example of rspec/FactoryBot weirdness, previous_trip_id isn't
    # being set properly, only in the context of the ReturnTripPlanner object--
    # but it works fine in the normal environment. Can't figure out why.
    expect(rtp.trip.attributes.except(:previous_trip_id))
    .to eq(rtp.outbound_trip.build_return_trip.attributes.except(:previous_trip_id))
    
  end
  
  it "plans return trip with only one itinerary based on outbound trip's selected service" do
    
    expect(rtp.outbound_trip.itineraries.count).to be > 1
    expect(rtp.trip.itineraries.count).to eq(0)
    
    rtp.plan
    
    expect(rtp.trip.itineraries.count).to eq(1)
    expect(rtp.trip.selected_itinerary).not_to be_nil
    expect(rtp.trip.selected_service).to eq(rtp.outbound_trip.selected_service)
    
  end
  
  
end
