require 'rails_helper'

RSpec.describe Booking, type: :model do
  
  # Attrs
  it { should respond_to :type, :status, :confirmation, :details } 
  
  # Methods
  it { should respond_to :booked?, :canceled?, :type_code }
  
  # Associations
  it { should have_one(:service) } 
  
  # Constants
  it "stores BOOKING_TYPES and other constants" do
    expect(Booking::BOOKING_TYPES).to be_a(Hash)
    expect(Booking::BOOKING_TYPE_CODES).to be_a(Array)
    expect(Booking::BOOKING_TYPE_CLASSES).to be_a(Array)    
  end
  
  describe "RidePilot Bookings" do
    let(:ride_pilot_booking_req) { create(:ride_pilot_booking, status: "requested") }
    let(:ride_pilot_booking_canc) { create(:ride_pilot_booking, status: "CANC") }

    it "stores RidePilot status code constants" do
      expect(RidePilotBooking::RIDE_PILOT_STATUSES).to be_a(Hash)
      expect(RidePilotBooking::BOOKED_TRIP_STATUS_CODES).to be_a(Array)
      expect(RidePilotBooking::CANCELED_TRIP_STATUS_CODES).to be_a(Array)
    end

    it "knows if it's booked based on status code" do      
      expect(ride_pilot_booking_req.booked?).to be true
      expect(ride_pilot_booking_canc.booked?).to be false
    end
    
    it "knows if it's canceled based on status code" do
      expect(ride_pilot_booking_canc.canceled?).to be true
      expect(ride_pilot_booking_req.canceled?).to be false
    end
    
  end
  
  
end
