namespace :db do
  namespace :sample do
    
    require 'tasks/helpers/samples_helper'
    include SamplesHelper
    
    desc "Setup Sample Landmarks"
    task landmarks: :environment do

      landmarks = [
                   {name: "Cambridge Systematics", street_number: "101", route: "Station Landing",
                   city: "Medford", state: "MA", zip: "02155", lat: "42.401697", lng: "-71.081818"},

                   {name: "Fenway Park", street_number: "4", route: "Yawkey Way",
                   city: "Boston", state: "MA", zip: "02215", lat: "42.346636", lng: "-71.096013"},

                   {name: "Massachusetts General Hospital", street_number: "55", route: "Fruit Street",
                   city: "Boston", state: "MA", zip: "02214", lat: "42.363215", lng: "-71.068903"}
                 ]

      landmarks.each do |landmark|
        Landmark.where(name: landmark[:name]).first_or_create!(landmark)
      end
    end

    desc "Setup Sample Eligibilities, with translations for each"
    task eligibilities: :environment do
      CharacteristicBuilder.new(:eligibility).build_all([
        { 
          code: 'medicaid',
          name: "Medicaid",
          note: "I am eligible for Medicaid.",
          question: "Are you eligible for Medicaid?" 
        },
        { 
          code: 'physically_disabled',
          name: "Physically Disabled",
          note: "I am physically disabled.",
          question: "Are you physically disabled?" 
        },
        { 
          code: 'ada',
          name: "ADA",
          note: "I am eligible for ADA.",
          question: "Are you eligible for ADA?" 
        },
        { 
          code: 'veteran',
          name: "Veteran",
          note: "I am a veteran.",
          question: "Are you a veteran?" 
        },
        { 
          code: 'over_65',
          name: "Over 65",
          note: "I am over 65.",
          question: "Are you over 65?" 
        }
      ])
    end

    desc "Setup Sample Accommodations"
    task accommodations: :environment do
      CharacteristicBuilder.new(:accommodation).build_all([
        { 
          code: 'folding_wheelchair',
          name: "Folding Wheelchair",
          note: "I have a folding wheelchair.",
          question: "Do you have a folding wheelchair?" 
        },
        { 
          code: 'motorized_wheelchair',
          name: "Motorized Wheelchair",
          note: "I have a motorized wheelchair.",
          question: "Do you have a motorized wheelchair?" 
        },
        { 
          code: 'driver_assistance',
          name: "Driver Assistance",
          note: "I need driver assistance.",
          question: "Do you need driver assistance?" 
        },
        { 
          code: 'curb_to_curb',
          name: "Curb to Curb",
          note: "I need curb to curb service.",
          question: "Do you need curb to curb service?" 
        },
        { 
          code: 'door_to_door',
          name: "Door to Door",
          note: "I need door to door service.",
          question: "Do you need door to door service?" 
        }
      ])
    end


    desc "Setup Sample Purposes"
    task purposes: :environment do
      CharacteristicBuilder.new(:purpose).build_all([
        { 
          code: 'grocery',
          name: "Grocery",
          note: "This is a grocery trip.",
          question: "Is this a grocery trip?" 
        },
        { 
          code: 'medical',
          name: "Medical",
          note: "This is a medical trip.",
          question: "Is this a medical trip?" 
        },
        { 
          code: 'shopping',
          name: "Shopping",
          note: "This is a shopping trip.",
          question: "Is this a shopping trip?" 
        }
      ])
    end

    desc "Setup Sample Services"
    task services: :environment do
      [
        {
          type: "Transit",
          name: "Sample Transit Service",
          gtfs_agency_id: "1",
          phone: "555-555-5555", 
          url: "http://www.mbta.com", 
          published: true
        },
        {
          type: "Paratransit",
          name: "Sample Paratransit Service 1",
          phone: "555-555-5555", 
          url: "http://www.mbta.com",
          accommodations: Accommodation.all,
          eligibilities: Eligibility.all,
          purposes: Purpose.all,
          published: true
        },
        {
          type: "Paratransit",
          name: "Sample Paratransit Service 2",
          phone: "555-555-5555", 
          url: "http://www.mbta.com",
          published: true
        },
        {
          type: "Taxi",
          name: "Sample Taxi Service",
          phone: "555-555-5555", 
          url: "http://www.taxi.com",
          fare_structure: :mileage,
          fare_details: { mileage_base_fare: 5.0, mileage_rate: 0.5 },
          published: true
        },
        {
          type: "Uber",
          name: "Sample Uber Service",
          phone: "555-555-5555", 
          url: "http://www.uber.com",
          published: true
        }
      ].each do |svc|
        puts "Creating #{svc[:type]} Service: #{svc[:name]}"
        Service.find_or_create_by(type: svc[:type], name: svc[:name])
               .update_attributes(svc)
      end

    end

    desc "Set Default Config Values"
    task config: :environment do
      Config.find_or_create_by(key: "open_trip_planner").update_attributes(value: "http://otp-ma.camsys-apps.com:8080/otp/routers/default")
    end

    desc "Test Samples"
    task test_geographies: :environment do
      puts "Uploading Sample Geographies..."
      counties_file = File.open("spec/files/test_sample_counties.zip")
      ShapefileUploader.new(counties_file,
        path: counties_file.path,
        content_type: "application/zip",
        geo_type: :county
      ).load
      cities_file = File.open("spec/files/test_sample_cities.zip")
      ShapefileUploader.new(cities_file,
        path: cities_file.path,
        content_type: "application/zip",
        geo_type: :city
      ).load
      zipcodes_file = File.open("spec/files/test_sample_zipcodes.zip")
      ShapefileUploader.new(zipcodes_file,
        path: zipcodes_file.path,
        content_type: "application/zip",
        geo_type: :zipcode,
        column_mappings: {name: "ZCTA5CE10"}
      ).load
    end

    desc "Feedback Samples"
    task feedback: :environment do
      Feedback.create(rating: 3, review: "OCC is meh", user: User.first)
      Feedback.create(rating: 5, review: "OCC is GREAT!!!", user: User.first)
    end

    desc "Stomping Grounds"
    task stomping_grounds: :environment do 
      u = User.staff.first # Grab the first staff at random

      places = [
        {name: "Home", street_number: "17", route: "Park Avenue",
        city: "Somerville", state: "MA", zip: "02144", lat: "42.398270", lng: "-71.122898"},
        {name: "Work", street_number: "101", route: "Station Landing",
        city: "Medford", state: "MA", zip: "02155", lat: "42.401697", lng: "-71.081818"}
      ]

      places.each do |place|
        StompingGround.where(name: place[:name], user: u).first_or_create!(place)
      end
    end
    
    desc "Sample Agencies"
    task agencies: :environment do      
      pa = PartnerAgency.find_or_create_by(name: "Test Partner Agency", 
          email: "test_partner_agency@oneclick.com", 
          published: true)
      ta = TransportationAgency.find_or_create_by(name: "Test Transportation Agency", 
          email: "test_transportation_agency@oneclick.com", 
          published: true)
      ta.services << Service.first
      ta.services << Service.last
          
      pa.add_staff(User.registered.last)
      ta.add_staff(User.registered.first)
      
      pa.save
      ta.save
    end

    #Load all sample data
    task all: [ :landmarks, :eligibilities, :accommodations, :purposes,
                :services, :config, :test_geographies, :feedback, :stomping_grounds,
                :agencies]

  end
end
