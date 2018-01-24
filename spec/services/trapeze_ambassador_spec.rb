require 'rails_helper'

RSpec.describe TrapezeAmbassador do
  # Create necessary configs
  let!(:trapeze_url) { create(:trapeze_url_config) }
  let!(:trapeze_token) { create(:trapeze_token_config) }  
  
  let(:trapeze_ambassador) { 
    create( :trapeze_ambassador )
  }

  it { should be_a BookingAmbassador }
  
  # Instance variables
  it { expect(trapeze_ambassador).to respond_to(
    :url, 
    :token, 
    :booking_options, 
    :itinerary,
    :service, 
    :trip, 
    :user   ) 
  }
  
  # Instance Methods
  it { expect(trapeze_ambassador).to respond_to(
    :book,
    :cancel,
    :status,
    :authentic_provider?,
    :booking_api,
    :authenticate_user?,
    :prebooking_questions)
  }
  
  # Stub out responses from RidePilot
  #let(:pass_validate_client_password) { true }
  
  #it "authenticates a user" do
    # Stub out status response for authenticate_customer call
  #  http_request_bundler.stub(:status!).and_return(ride_pilot_authenticate_customer_status)

  #  expect(rpa_booked.authenticate_user?).to be true
  #end
  
end