require 'rails_helper'

RSpec.describe UserBookingProfile, type: :model do
  let(:ride_pilot_user_profile) { create(:ride_pilot_user_profile)}
  
  # Attrs
  it { should respond_to :booking_api, :details, :external_user_id, 
                         :external_password, :encrypted_external_password } 
  
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
  
  it "encrypts external_password" do
    test_password = "TEST_PW"
    old_encrypted_pw = ride_pilot_user_profile.encrypted_external_password
    expect(ride_pilot_user_profile.external_password).not_to(eq(test_password))
    
    ride_pilot_user_profile.external_password = test_password
    ride_pilot_user_profile.save
  
    expect(ride_pilot_user_profile.external_password).to eq(test_password)
    expect(ride_pilot_user_profile.encrypted_external_password).not_to eq(test_password)
    expect(ride_pilot_user_profile.encrypted_external_password).not_to eq(old_encrypted_pw)
  end
  
  

end
