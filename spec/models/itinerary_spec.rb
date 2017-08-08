require 'rails_helper'

RSpec.describe Itinerary, type: :model do
  it { should belong_to :trip }
  it { should belong_to :service }
  it { should respond_to :start_time,
        :end_time, :legs, :walk_time, :transit_time,
        :cost, :trip_type, :walk_distance, :wait_time }

  let(:itinerary) { create(:transit_itinerary) }

  it 'duration returns sum of walk, transit, and wait time' do
    expect(itinerary.duration).to eq(itinerary.transit_time + itinerary.walk_time + itinerary.wait_time)
  end

  it 'selects itself' do
    itinerary.select
    expect(itinerary.selecting_trip).to eq(itinerary.trip)
  end

  it 'selects and unselects itself' do
    itinerary.select
    expect(itinerary.selecting_trip).to eq(itinerary.trip)

    itinerary.unselect
    itinerary.reload
    itinerary.trip.reload
    expect(itinerary.trip.selected_itinerary).to eq(nil)
  end
  
  
  ### BOOKING ###
  
  describe 'booking' do
    
    it { should respond_to :book, :cancel, :booked?, :canceled?, :booking_ambassador }
    
    let(:ride_pilot_itin) { create(:ride_pilot_itinerary, :unbooked)}
    
    it "creates the appropriate booking ambassador based on service" do
      
      rpa = ride_pilot_itin.booking_ambassador
      
      expect(rpa).to be_a(RidePilotAmbassador)
      expect(rpa.itinerary).to eq(ride_pilot_itin)
      expect(rpa.service).to eq(ride_pilot_itin.service)
      expect(rpa.trip).to eq(ride_pilot_itin.trip)
      expect(rpa.user).to eq(ride_pilot_itin.user)
      
    end
    
    # Build a stubbed RidePilotAmbassador
    let(:ride_pilot_ambassador) do 
      create(:ride_pilot_ambassador, opts: { itinerary: ride_pilot_itin })
    end
    before(:each) do
      allow(ride_pilot_itin).to receive(:booking_ambassador) { ride_pilot_ambassador }
      allow(ride_pilot_ambassador).to receive(:book) do
        create(:ride_pilot_booking, :booked, itinerary: ride_pilot_itin)
      end
      allow(ride_pilot_ambassador).to receive(:cancel) do
        create(:ride_pilot_booking, :canceled, itinerary: ride_pilot_itin)
      end
    end
    
    it "books itself via RidePilot" do
      expect(ride_pilot_itin.booked?).to be false
      ride_pilot_itin.book
      expect(ride_pilot_itin.booked?).to be true
    end
    
    it "cancels itself via RidePilot" do
      expect(ride_pilot_itin.canceled?).to be false
      ride_pilot_itin.cancel
      expect(ride_pilot_itin.canceled?).to be true
    end
    
  end

end
