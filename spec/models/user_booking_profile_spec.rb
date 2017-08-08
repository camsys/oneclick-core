require 'rails_helper'

RSpec.describe UserBookingProfile, type: :model do
  
  # Attrs
  it { should respond_to :booking_api, :details } 
  
  # Associations
  it { should belong_to(:user) }
  it { should belong_to(:service) }

end
