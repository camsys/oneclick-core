require 'rails_helper'
require 'cancan/matchers'

# NOTE: Some of the staff user tests that test abilities need to be updated to reflect
# new permissions/ authentication system
RSpec.describe User, type: :model do

  let!(:english_traveler) { create(:english_speaker, :eligible, :not_a_veteran, :needs_accommodation) }
  let!(:traveler) { create(:user) }
  let(:guest) { create(:guest) }

  it { should have_many :trips }
  it { should have_and_belong_to_many :accommodations }
  it { should respond_to :roles }
  it { should have_many(:user_eligibilities) }
  it { should have_many(:eligibilities).through(:user_eligibilities) }
  it { should have_many(:feedbacks) }
  it { should have_many(:alerts) }
  
  it_behaves_like "contactable", { email: :email }
  
  it 'returns a locale for a user' do
    expect(english_traveler.locale).to eq(english_traveler.preferred_locale) #This user has a preferred locale, so that one should be found
    expect(traveler.locale).to eq(Locale.find_by(name: "en")) #This user does not have a preferred locale, so English should be returned.
  end

  it 'returns the preferred trip types array' do
  	expect(english_traveler.preferred_trip_types).to eq(['transit', 'unicycle'])
  end

  it 'updates  basic attributes' do
    params = {first_name: "George", last_name: "Burdell", email: "gpburdell@email.com", lang: "en", preferred_trip_types: ['recumbent_bicycle', 'roller_blades']}
    traveler.update_basic_attributes params
    expect(traveler.email).to eq('gpburdell@email.com')
    expect(traveler.first_name).to eq('George')
    expect(traveler.last_name).to eq('Burdell')
    expect(traveler.locale).to eq(Locale.find_by(name: "en"))
    expect(traveler.preferred_trip_types).to eq(['recumbent_bicycle', 'roller_blades'])
  end

  it 'ensures email is always lowercase' do
    params = {first_name: "George", last_name: "Burdell", email: "gpbURdell@email.com", lang: "en", preferred_trip_types: ['recumbent_bicycle', 'roller_blades']}
    traveler.update_basic_attributes params
    expect(traveler.email).to eq('gpburdell@email.com')
  end

  it 'updates the password' do
    old_password_token = traveler.encrypted_password
    params = {password: "welcome_test_test1", password_confirmation: "welcome_test_test1"}
    traveler.update_basic_attributes params
    expect(traveler.encrypted_password).not_to eq(old_password_token)
  end

  it 'resets a user\'s access if the password is changed' do
    expect(traveler.access_locked?).to eq(false)
  
    traveler.lock_access!
    expect(traveler.access_locked?).to eq(true)
    
    traveler.update(password: "another_new_password1", password_confirmation: "another_new_password1")
    expect(traveler.access_locked?).to eq(false)
  end
  
  

  it 'will not update the password if the password_confirmation does not match' do
    params = {password: "welcome_test_test1", password_confirmation: "blahblah3"}
    expect{traveler.update_basic_attributes params}.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'updates eligibilities' do
    params = {over_65: false, veteran: true}
    traveler.update_eligibilities params
    expect(traveler.eligibilities.count).to eq(2)
    veteran = Eligibility.find_by(code: "veteran")
    over_65 = Eligibility.find_by(code: "over_65")
    expect(traveler.user_eligibilities.find_by(eligibility: veteran).value).to eq(true)
    expect(traveler.user_eligibilities.find_by(eligibility: over_65).value).to eq(false)
  end

  it 'updates accommodations' do
    params = {wheelchair: true, jacuzzi: false}
    traveler.update_accommodations params
    expect(traveler.accommodations.count).to eq(1)
    expect(traveler.accommodations.where(code: "wheelchair").count).to eq(1)
    expect(traveler.accommodations.where(code: "jacuzzi").count).to eq(0)
  end

  #Depracated after api/v1
  it 'updates_preferred_modes' do
    params = {attributes: {first_name: "George", last_name: "Burdell", email: "gpburdell@email.com", lang: "en"}, preferred_modes: ['recumbent_bicycle', 'roller_blades']}
    traveler.update_profile params
    expect(traveler.email).to eq('gpburdell@email.com')
    expect(traveler.first_name).to eq('George')
    expect(traveler.last_name).to eq('Burdell')
    expect(traveler.locale).to eq(Locale.find_by(name: "en"))
    expect(traveler.preferred_trip_types).to eq(['recumbent_bicycle', 'roller_blades'])
  end
  
  ### BOOKING ###
  describe 'booking' do
    let(:booking_user) { create(:user, :with_booking_profiles) }
    
    it { should have_many(:booking_profiles).dependent(:destroy) }
    it { should have_many(:bookings).through(:itineraries) }

    it "has booking_profile helper methods" do
      expect(booking_user.booking_profiles.count).to be > 1
      
      expect(booking_user.booking_profile).to eq(booking_user.booking_profiles.first)
      
      svc = booking_user.booking_profiles.last.service
      expect(booking_user.booking_profile_for(svc)).to eq(booking_user.booking_profiles.last)
    end

  end
  
  
  ### ROLES & CANCAN ABILITIES ###
  describe 'abilities & roles' do
    
    it "generates an auth token automatically on save" do
      expect(traveler.authentication_token).to be
      old_auth_token = traveler.authentication_token
      traveler.update_attributes(authentication_token: nil)
      traveler.reload
      expect(traveler.authentication_token).to be
      expect(traveler.authentication_token).not_to eq(old_auth_token)
    end
    
    describe "superusers" do
      
      let(:superuser) { create(:superuser) }
      subject(:ability) { Ability.new(superuser) }
      
      it "is a superuser, but not a staff, admin, traveler, or guest" do
        expect(superuser.superuser?).to be true
        expect(superuser.admin?).to be false
        expect(superuser.staff?).to be false
        expect(superuser.traveler?).to be false
        expect(superuser.guest?).to be false
      end
      it{ should be_able_to(:manage, :all) }
      
    end

    # Admin and staff user tests is going to be physical pain
    describe " transportation admins" do

      let(:admin) { create(:transportation_admin) }
      subject(:ability) { Ability.new(admin) }

      it "is an admin, but not a staff, superuser, traveler, or guest" do
        expect(admin.admin?).to be true
        expect(admin.superuser?).to be false
        expect(admin.staff?).to be false
        expect(admin.traveler?).to be false
        expect(admin.guest?).to be false
      end
      # NOTE: Will need to update the ability tests for transportation admins
      xit{ should be_able_to(:manage, :all) }

    end

    describe "staff users" do
      
      let(:agency) { create(:transportation_agency, :with_services)}
      let(:staff) { create(:user, :staff, staff_agency: agency)}
      subject(:ability) { Ability.new(staff) }
      let(:other_agency) { create(:partner_agency) }
      let(:fellow_staff) { create(:user, :staff, staff_agency: agency)}
      let(:other_staff) { create(:user, :staff, staff_agency: other_agency)}
      let(:other_service) { create(:service) }
      
      # General
      it "is a staff but not an admin, traveler, or guest" do
        expect(staff.staff?).to be true
        expect(staff.admin?).to be false
        expect(staff.guest?).to be false
        expect(staff.traveler?).to be false
      end
      it{ should_not  be_able_to( :manage,            :all) }

      # Agencies
      xit{ should      be_able_to( [:read, :update],   Agency) }
      xit{ should_not  be_able_to( :manage,            Agency) }
      xit{ should      be_able_to( [:read, :update],   agency) }
      xit{ should_not  be_able_to( [:read, :update],   other_agency) }
      
      # Staff
      it{ should      be_able_to( :read,            User) }
      it{ should      be_able_to( :read,            fellow_staff) }
      it{ should_not  be_able_to( :manage,            other_staff) }
      
      # Services
      it{ should      be_able_to( :read,            Service) }
      it{ should      be_able_to( :read,            agency.services.take) }
      it{ should_not  be_able_to( :manage,            other_service) }
      it "staff user should have many services" do
        expect(staff.services.count).to be > 0
        expect(staff.services.all?{|s| s.is_a?(Service)}).to be true
      end
      
      # Alerts
      xit{ should      be_able_to( :manage,            Alert) }
      
      describe "transportation staff users" do
        
        let(:transportation_agency) { create(:transportation_agency, :with_services) }
        let(:transportation_staff) { create(:user, :staff, staff_agency: transportation_agency)}
        subject(:ability) { Ability.new(transportation_staff) }
        let(:feedback) { create(:feedback, feedbackable: transportation_agency.services.take) }
        let(:other_feedback) { create(:service_feedback) }
        
        it "is a transportation_staff but not a partner_staff" do
          expect(transportation_staff.transportation_staff?).to be true
          expect(transportation_staff.partner_staff?).to be false
        end
        
        # Feedbacks
        it{ should      be_able_to( [:read, :update],   Feedback) }
        it{ should      be_able_to( [:read, :update],   feedback) }
        it{ should_not  be_able_to( [:read, :update],   other_feedback) }
        
      end
      
      describe "partner agency staff users" do
        
        let(:partner_agency) { create(:partner_agency, :with_services) }
        let(:partner_staff) { create(:user, :staff, staff_agency: partner_agency)}
        subject(:ability) { Ability.new(partner_staff) }
        let(:feedback) { create(:feedback, feedbackable: partner_agency.services.take) }
        let(:other_feedback) { create(:service_feedback) }
        
        xit "is a partner_staff but not a transportation_staff" do
          expect(partner_staff.partner_staff?).to be true
          expect(partner_staff.transportation_staff?).to be false
        end
        
        # Feedbacks
        xit{ should      be_able_to( [:read, :update],   Feedback) }
        xit{ should      be_able_to( [:read, :update],   feedback) }
        xit{ should      be_able_to( [:read, :update],   other_feedback) }
        
        # Reports
        xit{ should      be_able_to( :read,              :report) }
        
      end
      
    end
    
    describe "traveler users" do
      
      subject(:ability) { Ability.new(traveler) }
      
      it "is a traveler but not an admin, staff, or guest" do
        expect(traveler.traveler?).to be true
        expect(traveler.staff?).to be false
        expect(traveler.admin?).to be false
        expect(traveler.guest?).to be false
      end
      
      # shouldn't be able to do anything, this is just a test example
      it{ should_not  be_able_to(:read, Service) }
      
    end
    
    describe "guest users" do
      
      subject(:ability) { Ability.new(guest) }
      
      it "is a guest and a traveler but not an admin or staff" do
        expect(guest.traveler?).to be true
        expect(guest.staff?).to be false
        expect(guest.admin?).to be false
        expect(guest.guest?).to be true
      end
      
      # shouldn't be able to do anything, this is just a test example
      it{ should_not  be_able_to(:read, Service) }
      
      it "does NOT automatically generate an auth token" do
        expect(guest.authentication_token).to be_nil
        guest.save
        guest.reload
        expect(guest.authentication_token).to be_nil
      end
      
    end
    
  end

end
