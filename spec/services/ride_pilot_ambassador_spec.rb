require 'rails_helper'

RSpec.describe RidePilotAmbassador do
  # Create necessary configs
  let!(:ride_pilot_url) { create(:ride_pilot_url_config) }
  let!(:ride_pilot_token) { create(:ride_pilot_token_config) }  
  
  let(:http_request_bundler) { HTTPRequestBundler.new }
  let(:itinerary) { create(:ride_pilot_itinerary, :unbooked)}
  let(:booked_itin) { create(:ride_pilot_itinerary, :booked)}
  let(:ride_pilot_ambassador) { 
    create( :ride_pilot_ambassador, 
            opts: { http_request_bundler: http_request_bundler,
                    itinerary: itinerary }) 
  }
  let(:rpa_booked) {
    create( :ride_pilot_ambassador, 
            opts: { http_request_bundler: http_request_bundler,
                    itinerary: booked_itin }) 
  }
  
  it { should be_a BookingAmbassador }
  
  # Instance variables
  it { expect(ride_pilot_ambassador).to respond_to(
    :http_request_bundler, 
    :url, 
    :token, 
    :booking_options, 
    :itinerary,
    :service, 
    :trip, 
    :user   ) 
  }
  
  # Instance Methods
  it { expect(ride_pilot_ambassador).to respond_to(
    :book,
    :cancel,
    :status,
    :authenticate_provider,
    :authenticate_customer,
    :trip_purposes,
    :create_trip,
    :cancel_trip  ) 
  }
  
  # Stub out responses from RidePilot
  let(:ride_pilot_create_trip_response) { JSON.parse(File.read("spec/files/ride_pilot_response_create_trip.json")) }
  let(:ride_pilot_cancel_trip_response) { JSON.parse(File.read("spec/files/ride_pilot_response_cancel_trip.json")) }
  let(:ride_pilot_trip_status_response) { JSON.parse(File.read("spec/files/ride_pilot_response_trip_status.json")) }
  let(:ride_pilot_trip_purposes_response) { JSON.parse(File.read("spec/files/ride_pilot_response_trip_purposes.json")) }
  let(:ride_pilot_authenticate_customer_status) { "200 OK" }
  let(:ride_pilot_authenticate_provider_status) { "200 OK" }
  
  # Stub out HTTPRequestBundler to serve back fake RidePilot responses
  before(:each) do
    http_request_bundler.stub(:add).and_return(http_request_bundler)
  end
  
  it "books a trip" do
    http_request_bundler.stub(:response!).and_return(ride_pilot_create_trip_response)

    expect(itinerary.selected?).to be false
    expect(itinerary.booked?).to be false
    expect(itinerary.booking).to be_nil
    
    expect(ride_pilot_ambassador.book).to be_a(RidePilotBooking)
    itinerary.reload
    
    expect(itinerary.selected?).to be true
    expect(itinerary.booked?).to be true
    expect(itinerary.booking).to be_a(RidePilotBooking)
  end
  
  it "cancels a trip" do
    http_request_bundler.stub(:response!).and_return(ride_pilot_cancel_trip_response)

    expect(booked_itin.selected?).to be true
    expect(booked_itin.canceled?).to be false
    expect(booked_itin.booking).to be_a(RidePilotBooking)
    
    expect(rpa_booked.cancel).to be_a(RidePilotBooking)
    booked_itin.reload
    
    expect(booked_itin.selected?).to be false
    expect(booked_itin.canceled?).to be true
    expect(booked_itin.booking).to be_a(RidePilotBooking)
  end
  
  it "gets a trip's status" do
    # Stub out status response for a requested trip
    http_request_bundler.stub(:response!).and_return(ride_pilot_create_trip_response)
    
    expect(rpa_booked.status).to be_a(RidePilotBooking)
    expect(rpa_booked.status.booked?).to be true
    expect(rpa_booked.status.canceled?).to be false
    
    # Stub out status response for a canceled trip
    http_request_bundler.stub(:response!).and_return(ride_pilot_cancel_trip_response)
    
    expect(rpa_booked.status).to be_a(RidePilotBooking)
    expect(rpa_booked.status.booked?).to be false
    expect(rpa_booked.status.canceled?).to be true
  end
  
  it "authenticates a user" do
    # Stub out status response for authenticate_customer call
    http_request_bundler.stub(:status!).and_return(ride_pilot_authenticate_customer_status)

    expect(rpa_booked.authenticate_user?).to be true
  end
  
  it "makes RidePilot create_trip call" do
    http_request_bundler.stub(:response!).and_return(ride_pilot_create_trip_response)
    expect(ride_pilot_ambassador.create_trip).to eq(ride_pilot_create_trip_response)
  end
  
  it "makes RidePilot cancel_trip call" do
    http_request_bundler.stub(:response!).and_return(ride_pilot_cancel_trip_response)
    expect(ride_pilot_ambassador.cancel_trip).to eq(ride_pilot_cancel_trip_response)
  end
  
  it "makes RidePilot trip_status call" do
    http_request_bundler.stub(:response!).and_return(ride_pilot_trip_status_response)
    expect(ride_pilot_ambassador.trip_status).to eq(ride_pilot_trip_status_response)
  end
  
  it "makes RidePilot trip_purposes call" do
    http_request_bundler.stub(:response!).and_return(ride_pilot_trip_purposes_response)
    expect(ride_pilot_ambassador.trip_purposes).to eq(ride_pilot_trip_purposes_response)
  end
  
  it "makes RidePilot authenticate_customer call" do
    http_request_bundler.stub(:status!).and_return(ride_pilot_authenticate_customer_status)
    expect(ride_pilot_ambassador.authenticate_customer).to eq(ride_pilot_authenticate_customer_status)
  end
  
  it "makes RidePilot authenticate_provider call" do
    http_request_bundler.stub(:status!).and_return(ride_pilot_authenticate_provider_status)
    expect(ride_pilot_ambassador.authenticate_provider).to eq(ride_pilot_authenticate_provider_status)
  end
  
end
