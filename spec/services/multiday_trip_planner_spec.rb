require 'rails_helper'

RSpec.describe MultidayTripPlanner do
  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  
  # Stubbed OTP Responses
  let!(:otp_car_response) { JSON.parse(File.read("spec/files/otp_response_car.json")) }
  let!(:paratransit) { create(:paratransit_service, :medical_only, :ecolane_bookable) }
  let!(:taxi) { create(:taxi_service) }
  let!(:uber) { create(:uber_service) }
  let!(:lyft) { create(:lyft_service) }
  let!(:transit) { create(:transit_service)}

  # Stubbed HTTPRequestBundler with fake OTP response
  before(:each) do
    HTTPRequestBundler.any_instance.stub(:response) { otp_car_response }
    HTTPRequestBundler.any_instance.stub(:make_calls) { {} }
    HTTPRequestBundler.any_instance.stub(:add) { true }
  end
  
  let(:trip_types) { [:paratransit, :taxi] }
  let(:mtp) { create(:multiday_trip_planner, options: {trip_types: trip_types}) }

  it { expect(mtp).to be_a TripPlanner } 

  it 'accepts an array of trip times, and plans a trip for each trip time' do
    expect(mtp.trips.count).to eq(0)

    Paratransit.all.each do |paratransit|
      create(:user_booking_profile, service_id: paratransit.id, user: mtp.trip_template.user)
    end
    
    mtp.plan
    
    expect(mtp.trips.count).to eq(mtp.trip_times.count)
    
    # Expect each trip to match the template, and have itineraries
    mtp.trips.each do |trip|
      expect(trip.origin).to eq(mtp.trip_template.origin)
      expect(trip.destination).to eq(mtp.trip_template.destination)
      expect(trip.arrive_by).to eq(mtp.trip_template.arrive_by)
      expect(trip.itineraries.count).to be > 0
      expect(trip.itineraries.pluck(:trip_type).map(&:to_sym)).to eq(trip_types)
    end
  end
  
  
end
