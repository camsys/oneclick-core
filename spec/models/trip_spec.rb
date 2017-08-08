require 'rails_helper'

RSpec.describe Trip, type: :model do
  it { should belong_to :user }
  it { should have_many(:itineraries).dependent(:destroy) }
  it { should belong_to(:origin).class_name('Waypoint').dependent(:destroy) }
  it { should belong_to(:destination).class_name('Waypoint').dependent(:destroy) }
  it { should belong_to(:purpose) }

  let(:itinerary) { create(:transit_itinerary) }

  it 'unselects itself' do
    trip = itinerary.trip
    itinerary.select
    expect(trip.selected_itinerary).to eq(itinerary)

    trip.unselect
    trip.reload
    expect(trip.selected_itinerary).to eq(nil)
  end
  
  
  ### BOOKING ###
  
  describe 'booking' do
    
    it { should have_one(:booking) }
    it { should respond_to(:build_booking, :booking_status, :booked?, :canceled?)}
    
  end

end
