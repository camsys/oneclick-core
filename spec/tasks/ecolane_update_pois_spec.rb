require 'rails_helper'
require 'rake'

RSpec.describe 'ecolane:update_pois', type: :task do
  before(:all) do
    Rake.application.rake_require 'tasks/ecolane'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    Rake::Task['ecolane:update_pois'].reenable
    allow(STDOUT).to receive(:puts).and_call_original # Allow puts to be called normally

    # Setup necessary data
    @agency = create(:transportation_agency, name: 'Test Agency')
    @rabbit_south_service = create(:paratransit_service, agency: @agency, booking_api: 'ecolane', booking_details: {
      external_id: 'sandbox-rabbit-south',
      token: 'token1',
      api_key: 'api_key1',
      home_counties: 'County South'
    })

    @rabbit_north_service = create(:paratransit_service, agency: @agency, booking_api: 'ecolane', booking_details: {
      external_id: 'sandbox-rabbit-north',
      token: 'token2',
      api_key: 'api_key2',
      home_counties: 'County North'
    })

    @mcta_service = create(:paratransit_service, agency: @agency, booking_api: 'ecolane', booking_details: {
      external_id: 'sandbox-mcta',
      token: 'token3',
      api_key: 'api_key3',
      home_counties: 'Monroe County'
    })

    # Create a landmark to be updated
    @existing_landmark = Landmark.create(
      name: '104 KNOB CT, TUNKHANNOCK',
      street_number: '104',
      route: 'KNOB CT',
      city: 'TUNKHANNOCK',
      state: '',
      zip: '',
      old: false,
      lat: 40.9995,
      lng: -75.5071,
      geom: RGeo::Geos.factory.point(-75.5071, 40.9995),
      county: 'WYOMING',
      search_text: '104 KNOB CT, TUNKHANNOCK '
    )

    # Verify the landmark creation
    raise "Failed to create landmark" unless Landmark.exists?(@existing_landmark.id)

    # Mock the get_pois method to return new POIs
    allow_any_instance_of(EcolaneAmbassador).to receive(:get_pois).and_return([
      { name: 'New POI', street_number: '456', route: 'Second St', city: 'New City', state: 'TS', zip: '67890', lat: 12.34, lng: 56.78 },
      { name: '104 KNOB CT, TUNKHANNOCK', street_number: '104', route: 'KNOB CT', city: 'TUNKHANNOCK', state: '', zip: '', lat: 40.9995, lng: -75.5071 }
    ])
  end

  it 'updates POIs correctly' do
    puts "Before task: Landmark.count = #{Landmark.count}"
    puts "Before task: Existing Landmark ID = #{@existing_landmark.id}"
    puts "Before task: Existing Landmark exists? = #{Landmark.exists?(@existing_landmark.id)}"
    puts "Before task: All Landmarks = #{Landmark.all.pluck(:id, :name, :old, :lat, :lng).inspect}"
    expect(Landmark.exists?(@existing_landmark.id)).to be_truthy

    Rake::Task['ecolane:update_pois'].invoke

    puts "After task: Landmark.count = #{Landmark.count}"
    puts "After task: Existing Landmark exists? = #{Landmark.exists?(@existing_landmark.id)}"
    puts "After task: All Landmarks = #{Landmark.all.pluck(:id, :name, :old, :lat, :lng).inspect}"

    # Check that the new POI is created
    new_poi = Landmark.find_by(name: 'New POI')
    puts "New POI: #{new_poi.attributes}" if new_poi
    expect(new_poi).not_to be_nil
    expect(new_poi.old).to be false
    expect(new_poi.city).to eq('New City')

    # Check that the updated POI is created with the same name but new attributes
    updated_poi = Landmark.find_by(name: '104 KNOB CT, TUNKHANNOCK')
    expect(updated_poi).not_to be_nil
    expect(updated_poi.old).to be false
    expect(updated_poi.lat).to eq(40.9995)
    expect(updated_poi.lng.to_f).to eq(-75.5071.to_f)

    # Verify that the old landmark has been replaced
    expect(Landmark.exists?(@existing_landmark.id)).to be_falsey
  end

  it 'marks old POIs as old' do
    puts "Before task (old POIs): #{Landmark.is_old.pluck(:id, :name).inspect}"
    
    Rake::Task['ecolane:update_pois'].invoke

    puts "After task (old POIs): #{Landmark.is_old.pluck(:id, :name).inspect}"

    # Check that old POIs are marked as old
    old_pois = Landmark.is_old
    expect(old_pois).not_to include(@existing_landmark)
  end

  it 'ensures no POIs have old set to true' do
    Rake::Task['ecolane:update_pois'].invoke

    expect(Landmark.where(old: true).count).to eq(0)
  end

  it 'ensures rabbitsouth and rabbitnorth have the same number of landmarks if they use the same system' do
    Rake::Task['ecolane:update_pois'].invoke

    rabbit_south_landmarks_count = Landmark.joins(:services).where(services: { id: @rabbit_south_service.id }).count
    rabbit_north_landmarks_count = Landmark.joins(:services).where(services: { id: @rabbit_north_service.id }).count

    expect(rabbit_south_landmarks_count).to eq(rabbit_north_landmarks_count)
  end

  it 'ensures mcta service has a distinct set of landmarks' do
    Rake::Task['ecolane:update_pois'].invoke

    mcta_landmarks_count = Landmark.joins(:services).where(services: { id: @mcta_service.id }).count
    rabbit_services_landmarks_count = Landmark.joins(:services).where(services: { id: [@rabbit_south_service.id, @rabbit_north_service.id] }).distinct.count

    expect(mcta_landmarks_count).not_to eq(rabbit_services_landmarks_count)
  end
end
