require 'rails_helper'

RSpec.describe Admin::BookingProfilesController, type: :controller do
  let!(:agency) { create(:transportation_agency) }
  let!(:service) { create(:service, agency: agency) }
  let!(:booking_profiles) { create_list(:user_booking_profile, 3, service: service) }
  let!(:other_booking_profiles) { create_list(:user_booking_profile, 2) } # Assuming this factory creates profiles associated with a different service/agency

  let(:superuser) { create(:superuser) }
  let(:staff) { create(:staff_user, staff_agency: agency) }
  let(:traveler) { create(:user) }

  context "while signed in as a superuser" do
    before(:each) { sign_in superuser }
    
    it "returns all booking profiles" do
      get :index
      expect(response).to be_success
      expect(assigns(:booking_profiles).count).to eq(UserBookingProfile.all.count)
    end
  end

  context "while signed in as a staff" do
    before(:each) { sign_in staff }
    
    it "returns only booking profiles related to user's agency" do
      get :index
      expect(response).to be_success
      expect(assigns(:booking_profiles)).to match_array(booking_profiles)
    end
    
    it "does not return booking profiles of other agencies" do
      get :index
      expect(assigns(:booking_profiles)).not_to include(*other_booking_profiles)
    end
  end
end