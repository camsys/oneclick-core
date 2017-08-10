require 'rails_helper'

RSpec.describe UserBookingProfile, type: :model do
  let(:ride_pilot_user_profile) { create(:ride_pilot_user_profile)}
  
  # Attrs
  it { should respond_to :booking_api, :details } 
  
  # Associations
  it { should belong_to(:user) }
  it { should belong_to(:service) }
  
  # Methods
  it { should respond_to :booking_ambassador, :authenticate? }

  it "returns the appropriate booking ambassador based on the booking_api field" do
    rpa = ride_pilot_user_profile.booking_ambassador
    
    expect(rpa).to be_a(RidePilotAmbassador)
    expect(rpa.booking_profile).to eq(ride_pilot_user_profile)
  end

end
