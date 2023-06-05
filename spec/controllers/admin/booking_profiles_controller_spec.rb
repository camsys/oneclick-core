require 'rails_helper'

RSpec.describe Admin::BookingProfilesController, type: :controller do
  let!(:superuser) { create(:user, :superuser) }
  let!(:admin) { create(:user, :admin) }
  let!(:oversight_agency) { create(:oversight_agency) }
  let!(:oversight_user) { create(:user, current_agency_id: oversight_agency.id) }
  let!(:normal_user) { create(:user) }

  let!(:service) { create(:service, agency: oversight_agency) }

  let!(:superuser_booking_profile) { create(:user_booking_profile, user: superuser) }
  let!(:admin_booking_profile) { create(:user_booking_profile, user: admin) }
  let!(:oversight_booking_profile) { create(:user_booking_profile, user: oversight_user, service: service) }
  let!(:normal_booking_profile) { create(:user_booking_profile, user: normal_user) }

  describe 'GET #index' do
    context "when superuser is signed in" do
      before do
        sign_in superuser
        get :index
      end

      it "assigns all booking profiles to @booking_profiles" do
        expect(assigns(:booking_profiles)).to match_array(UserBookingProfile.all)
      end
    end

    context 'when admin is signed in' do
      before do
        sign_in admin
        get :index
      end

      it 'assigns all booking profiles to @booking_profiles' do
        expect(assigns(:booking_profiles)).to match_array([superuser_booking_profile, admin_booking_profile, oversight_booking_profile, normal_booking_profile])
      end
    end

    context 'when oversight agency user is signed in' do
      before do
        sign_in oversight_user
        get :index
      end

      it 'assigns booking profiles of the services they oversee to @booking_profiles' do
        expect(assigns(:booking_profiles)).to match_array([oversight_booking_profile])
      end

      it 'only assigns booking profiles related to their agency' do
        expect(assigns(:booking_profiles)).to all(have_attributes(service: have_attributes(agency: oversight_agency)))
      end
    end

    context 'when normal user is signed in' do
      before do
        sign_in normal_user
        get :index
      end

      it 'assigns their own booking profiles to @booking_profiles' do
        expect(assigns(:booking_profiles)).to match_array([normal_booking_profile])
      end
    end
  end
end
