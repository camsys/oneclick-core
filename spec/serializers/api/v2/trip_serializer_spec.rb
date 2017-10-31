require 'rails_helper'

RSpec.describe Api::V2::TripSerializer, type: :serializer do
  
  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  before(:each) { create(:uber_token) }
  
  before(:each) do
    create(:paratransit_service, :accommodating, :strict, :medical_only)
    create(:taxi_service)
    create(:transit_service)
    create(:paratransit_service)
  end
  
  let(:trip_planner) { create(:trip_planner) }
  
  let(:basic_attributes) {
    [
      :id, 
      :arrive_by, 
      :trip_time
    ]
  }
  
  # has_many associations
  let(:array_attributes) {
    [
      :itineraries,
      :accommodations,
      :eligibilities,
      :purposes
    ]
  }
  
  # belongs_to associations
  let(:hash_attributes) {
    [
      :user,
      :origin,
      :destination
    ]
  }
  
  it "faithfully serializes a trip" do
    
    # Plan a trip so that it gets itineraries, and relevant eligibilities, accommodations, and purposes
    trip_planner.plan
    
    # Pull the trip out of the trip_planner, copy over its relevant characteristics, and serialize it
    trip = trip_planner.trip
    trip.relevant_accommodations = trip_planner.relevant_accommodations
    trip.relevant_eligibilities = trip_planner.relevant_eligibilities
    trip.relevant_purposes = trip_planner.relevant_purposes
    serialization = Api::V2::TripSerializer.new(trip, scope: { locale: "en" }).to_h
    
    # Check if basic attributes serialized properly
    basic_attributes.each do |attr|
      expect(serialization[attr]).to eq(trip.send(attr))
    end
    
    # Check if array attributes were serialized
    array_attributes.each do |attr|
      expect(serialization[attr]).to be
    end
    
    # Check if array attributes have the right lengths
    expect(serialization[:itineraries].count).to eq(trip.itineraries.count)
    expect(serialization[:accommodations].count).to eq(trip_planner.relevant_accommodations.count)
    expect(serialization[:eligibilities].count).to eq(trip_planner.relevant_eligibilities.count)
    expect(serialization[:purposes].count).to eq(trip_planner.relevant_purposes.count)
    
    # Check if hash attributes were serialized
    hash_attributes.each do |attr|
      expect(serialization[attr]).to be
    end
    
    # Check if hash attributes match the appropriate associated object
    expect(serialization[:user][:email] || serialization[:user].try(:email))
          .to eq(trip.user.email)
    expect(serialization[:origin][:formatted_address] || serialization[:origin].try(:formatted_address))
          .to eq(trip.origin.formatted_address)
    expect(serialization[:destination][:formatted_address] || serialization[:destination].try(:formatted_address))
          .to eq(trip.destination.formatted_address)
  
  end

end
