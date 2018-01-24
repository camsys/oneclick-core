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
  
end