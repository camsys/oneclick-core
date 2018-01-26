require 'rails_helper'

RSpec.describe Trip, type: :model do
  it { should belong_to :user }
  it { should have_many(:itineraries).dependent(:destroy) }
  it { should belong_to(:origin).class_name('Waypoint').dependent(:destroy) }
  it { should belong_to(:destination).class_name('Waypoint').dependent(:destroy) }
  it { should belong_to(:purpose) }
  it { should belong_to(:previous_trip).class_name('Trip') }
  it { should have_one(:next_trip).class_name('Trip').dependent(:nullify) }

  # Instance Methods
  it { should respond_to(
      :unselect,
      :wday,
      :secs,
      :trip_type,
      :arrival_time,
      :build_return_trip,
      :partner_agency_in
    )}

  let(:itinerary) { create(:transit_itinerary) }
  let(:trip) { create(:trip) }

  it 'unselects itself' do
    trip = itinerary.trip
    itinerary.select
    expect(trip.selected_itinerary).to eq(itinerary)

    trip.unselect
    trip.reload
    expect(trip.selected_itinerary).to eq(nil)
  end
  
  it "builds a return trip based on itself, accepting duration param" do
    return_trip = trip.build_return_trip(options: {duration: 2.hours})
    expect(return_trip.origin).to eq(trip.destination)
    expect(return_trip.destination).to eq(trip.origin)
    expect(return_trip.purpose).to eq(trip.purpose)
    expect(return_trip.user).to eq(trip.user)
    expect(return_trip.arrive_by).to be false
    expect(return_trip.trip_time).to eq(trip.arrival_time + 2.hours)
    expect(return_trip.previous_trip).to eq(trip)
    expect(trip.next_trip).to eq(return_trip)
  end

  
  ### BOOKING ###
  
  describe 'booking' do
    
    it { should have_one(:booking) }
    it { should respond_to(:build_booking, :booking_status, :booked?, :canceled?)}
    
  end

end
