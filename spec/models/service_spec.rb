require 'rails_helper'

RSpec.describe Service, type: :model do
  #Create Configs
  before(:all) { create(:ride_pilot_url_config) }
  before(:all) { create(:ride_pilot_token_config) } 
  before(:all) { create(:otp_config) }
  before(:all) { create(:tff_config) }
  before(:all) { create(:uber_token) }
  before(:all) { create(:lyft_client_token) }

  it { should respond_to :name, :logo, :type, :email, :phone, :url, :gtfs_agency_id }
  it { should have_many(:itineraries) }
  it { should have_many(:feedbacks) }
  
  it_behaves_like "publishable"
  it_behaves_like "archivable"
  it_behaves_like "describable"
  it_behaves_like "contactable", { phone: :phone, email: :email, url: :url }

  let(:service) { create(:service) }
  let(:transit) { create(:transit_service) }
  let(:paratransit) { create(:paratransit_service) }
  let(:taxi) { create(:taxi_service) }
  let(:user) { create(:user) }

  let(:trip_1) { create(:trip)} # Trip all in MA
  let(:trip_1_flipped) { create(:trip, origin: trip_1.destination, destination: trip_1.origin)}
  let(:trip_2) { create(:trip, destination: create(:way_out_point)) } # One end in CA
  let(:trip_3) { create(:trip, origin: create(:way_out_point), destination: create(:way_out_point_2)) } # Both ends in CA

  it 'should have a logo with a thumbnail version' do
    expect(service.logo_url).to be
    expect(service.logo.content_type[0..4]).to eq("image")
    expect(service.logo.thumb).to be
  end

  it 'transit service should be a Transit and have appropriate attributes' do
    expect(transit).to be
    expect(transit).to be_a(Transit)
    expect(transit.gtfs_agency_id).to be
  end

  it 'paratransit service should be a Paratransit and have appropriate attributes' do
    expect(paratransit).to be
    expect(paratransit).to be_a(Paratransit)
  end

  it 'taxi service should be a Taxi and have appropriate attributes' do
    expect(taxi).to be
    expect(taxi).to be_a(Taxi)
  end

  
  ### CHARACTERISTICS ###
  describe "characteristics" do
    
    let!(:jacuzzi) { FactoryBot.create :jacuzzi }
    let!(:wheelchair) { FactoryBot.create :wheelchair }
    let!(:eligibility) { FactoryBot.create :eligibility }
    
    it { should have_and_belong_to_many :accommodations }
    it { should have_and_belong_to_many :eligibilities }
    it { should have_many :purposes }
    
    # For Purposes Testing
    let(:medical_service) { create(:paratransit_service, :medical_only, :no_geography) }
    let(:all_purpose_service) { create(:paratransit_service, :no_geography) }
    let(:metallica_trip) { create(:trip, :going_to_see_metallica) }
    
    it 'should be available to users if it has all necessary accommodations' do
      # Make the paratransit service accommodating
      paratransit.accommodations += [jacuzzi, wheelchair]

      # The user needs no accommodations
      expect(paratransit.accommodates?(user)).to be true

      # Make the user need accommodations
      user.accommodations += [jacuzzi, wheelchair]

      # The service should still be accommodating
      expect(paratransit.accommodates?(user)).to be true
    end

    it 'should be unavailable to users if it lacks a necessary accommodation' do
      # The user needs no accommodations, this service should be good
      expect(paratransit.accommodates?(user)).to be true

      # Make the user need accommodations
      user.accommodations += [jacuzzi, wheelchair]

      # This service does not provide the above accommodations
      expect(paratransit.accommodates?(user)).to be false
    end

    it 'should be available to users that meet all eligibility requirements' do
      # Make the paratransit service strict
      paratransit.eligibilities << eligibility

      # Make the user eligible
      ue = UserEligibility.where(user: user, eligibility: eligibility).first_or_create
      ue.value = true
      ue.save

      # The user should be eligible
      expect(paratransit.accepts_eligibility_of?(user)).to be true
    end

    it 'should be unavailable to users that do not meet all eligibility requirements' do
      # Make the paratransit service strict
      paratransit.eligibilities << eligibility

      # The user should not be eligible
      expect(paratransit.accepts_eligibility_of?(user)).to be false
    end
    
    it 'should be available for trips based on purpose' do
      expect(all_purpose_service.available_for? metallica_trip).to eq(true)
    end

    it 'should be (un)available for trips based on purpose' do
      expect(medical_service.available_for? metallica_trip).to eq(false)
    end
    
  end
  
  
  ### GEOGRAPHY ###
  describe "geography" do
    it { should belong_to(:start_or_end_area).dependent(:destroy)}
    it { should belong_to(:trip_within_area).dependent(:destroy)}
    
    # For geographies testing:
    let(:service_0) { create(:paratransit_service, start_or_end_area: nil, trip_within_area: nil) } # No coverage areas set
    let(:service_1a) { create(:paratransit_service, trip_within_area: nil) } # Only start/end area set
    let(:service_1b) { create(:paratransit_service, start_or_end_area: nil) } # Only trip_within_area area set
    let(:service_2) { create(:paratransit_service) } # Both coverage areas set
    
    it 'services with no service areas should always be available' do
      expect(service_0.available_by_geography_for?(trip_1)).to be true
      expect(service_0.available_by_geography_for?(trip_2)).to be true
      expect(service_0.available_by_geography_for?(trip_3)).to be true
    end

    it 'services should be (un)available by start_or_end_area' do
      expect(service_1a.available_by_geography_for?(trip_1)).to be true
      expect(service_1a.available_by_geography_for?(trip_2)).to be true
      expect(service_1a.available_by_geography_for?(trip_3)).to be false
    end

    it 'services should be (un)available by trip_within_area' do
      expect(service_1b.available_by_geography_for?(trip_1)).to be true
      expect(service_1b.available_by_geography_for?(trip_2)).to be false
      expect(service_1b.available_by_geography_for?(trip_3)).to be false
    end

    it 'services should be (un)available by both start_or_end_area and trip_within_area' do
      expect(service_2.available_by_geography_for?(trip_1)).to be true
      expect(service_2.available_by_geography_for?(trip_2)).to be false
      expect(service_2.available_by_geography_for?(trip_3)).to be false
    end

    it 'start_or_end_area should work in both directions' do
      expect(service_2.available_by_geography_for?(trip_1)).to be true
      expect(service_2.available_by_geography_for?(trip_1_flipped)).to be true
    end
    
  end
  
  
  ### SCHEDULES ###
  describe 'schedules' do
    
    it { should have_many(:schedules) }
  
    # For schedules testing:
    let(:weekday_day_trip) { create(:trip, :weekday_day) }
    let(:weekday_night_trip) { create(:trip, :weekday_night) }
    let(:weekend_trip) { create(:trip, :weekend_day) }
    let(:service_with_schedules) { create(:paratransit_service, :with_schedules) }
    let(:service_without_schedules) { create(:paratransit_service) }
    let(:service_with_micro_schedules) { create(:paratransit_service, :with_micro_schedules) }
    let(:service_with_overlapping_schedules) { create(:paratransit_service, :with_overlapping_schedules)}
    
    it 'should be (un)available for trips based on schedule' do
      expect(service_with_schedules.available_by_schedule_for?(weekday_day_trip)).to be true
      expect(service_without_schedules.available_by_schedule_for?(weekday_day_trip)).to be true
      expect(service_with_micro_schedules.available_by_schedule_for?(weekday_day_trip)).to be false
      expect(service_with_schedules.available_by_schedule_for?(weekday_night_trip)).to be false
      expect(service_without_schedules.available_by_schedule_for?(weekday_night_trip)).to be true
      expect(service_with_micro_schedules.available_by_schedule_for?(weekday_night_trip)).to be false
      expect(service_with_schedules.available_by_schedule_for?(weekend_trip)).to be false
      expect(service_without_schedules.available_by_schedule_for?(weekend_trip)).to be true
      expect(service_with_micro_schedules.available_by_schedule_for?(weekend_trip)).to be false
    end
    
    it 'should consolidate its schedules after saving' do
      expect(service_with_overlapping_schedules.schedules.count).to eq(3)
      start_time = service_with_overlapping_schedules.schedules.pluck(:start_time).min
      end_time = service_with_overlapping_schedules.schedules.pluck(:end_time).max
      
      service_with_overlapping_schedules.save
      
      expect(service_with_overlapping_schedules.schedules.count).to eq(1)
      expect(service_with_overlapping_schedules.schedules.first.start_time).to eq(start_time)
      expect(service_with_overlapping_schedules.schedules.first.end_time).to eq(end_time)
    end
    
  end


  ### FARES ###
  describe "fares" do
    it { should respond_to :fare_structure, :fare_details }
    it { should have_many(:fare_zones) }
    it { should have_many(:fare_zone_regions).through(:fare_zones) }

    # For Fares testing
    let(:flat_fare_service) { create(:taxi_service, :flat_fare) }
    let(:mileage_fare_service) { create(:paratransit_service, :mileage_fare) }
    let(:zone_fare_service) { create(:paratransit_service, :zone_fare) }
    let(:tff_fare_service) { create(:taxi_service, :taxi_fare_finder_fare) }
    let(:empty_fare_service) { create(:paratransit_service, :empty_fare) }
    let(:url_fare_service) { create(:paratransit_service, :url_fare) }    
    let(:trip_ab) { trip_1 }
    let(:trip_ba) { trip_1_flipped }
    let(:trip_aa) { create(:trip, origin: create(:waypoint_02139), destination: create(:waypoint_02139))}
    let(:trip_bb) { create(:trip, origin: create(:waypoint_02140), destination: create(:waypoint_02140))}

    it 'should calculate flat fares' do
      expect(flat_fare_service.fare_for(trip_1)).to eq(flat_fare_service.fare_details[:flat_base_fare])
    end

    it 'should calculate mileage fares' do
      trip_distance = 1000 # in meters
      trip_dist_mi = trip_distance * 0.000621371 # in miles
      mileage_base_fare = mileage_fare_service.fare_details[:mileage_base_fare]
      mileage_rate = mileage_fare_service.fare_details[:mileage_rate]
      mileage_otp_response = { "plan" => { "itineraries" => [ {
        "legs" => [ "distance" => trip_distance ]
      } ] } }
      # Make an object double for HTTPRequestBundler that sends back dummy OTP responses
      hrb = object_double(HTTPRequestBundler.new, response: mileage_otp_response, make_calls: {}, add: true, response_status_code: '200')
      expect(mileage_fare_service.fare_for(trip_1, http_request_bundler: hrb)).to eq((mileage_base_fare + mileage_rate * trip_dist_mi).round(2))
    end

    it 'should calculate zone fares' do
      fare_table = zone_fare_service.fare_details[:fare_table]

      # trip from a to a should have fare 1.0
      expect(zone_fare_service.fare_for(trip_aa)).to eq(fare_table[:a][:a])

      # trip from a to b should have fare 2.0
      expect(zone_fare_service.fare_for(trip_ab)).to eq(fare_table[:a][:b])

      # trip from b to a should have fare 3.0
      expect(zone_fare_service.fare_for(trip_ba)).to eq(fare_table[:b][:a])

      # trip from b to b should have fare 4.0
      expect(zone_fare_service.fare_for(trip_bb)).to eq(fare_table[:b][:b])

      # trip from a to elsewhere should have fare nil
      expect(zone_fare_service.fare_for(trip_2)).to eq(FareHelper::NO_FARE)

    end

    it 'should calculate taxi fare finder fares' do
      fare = 10.0
      tff_response = { 'total_fare' => fare, 'status' => 'OK' }
      # Make an object double for HTTPRequestBundler that sends back dummy TFF responses
      hrb = object_double(HTTPRequestBundler.new, response: tff_response, make_calls: {}, add: true, response_status_code: '200')
      expect(tff_fare_service.fare_for(trip_1, http_request_bundler: hrb)).to eq(fare)
    end
    
    it 'should calculate empty fare' do
      expect(empty_fare_service.fare_for(trip_1)).to be_nil
    end
    
    it 'should calculate url fare' do
      expect(url_fare_service.fare_for(trip_1)).to be_nil
    end

    
  end
  
  
  ### BOOKING ###
  
  describe 'booking' do
    
    it { should respond_to(:booking_api, :booking_details) }
    
    let(:ride_pilot_service) { create(:paratransit_service, :ride_pilot_bookable) }
    let(:no_booking_service) { create(:paratransit_service, booking_api: "not_a_real_booking_api") }
    
    it "returns the appropriate booking ambassador based on the booking_api field" do
      rpa = ride_pilot_service.booking_ambassador
      
      expect(rpa).to be_a(RidePilotAmbassador)
      expect(rpa.service).to eq(ride_pilot_service)
      expect(no_booking_service.booking_ambassador).to be_nil
    end

    it "should not be valid because the ridepilot credentials cannot be verified" do
      service.should be_valid
      service.booking_api = "ride_pilot"
      service.booking_details = { provider_id: 0 }        
      service.should_not be_valid
    end
    
  end

end
