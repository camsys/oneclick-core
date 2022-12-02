require 'rails_helper'

RSpec.describe Api::V1::ItinerarySerializer, type: :serializer do
  include ScheduleHelper

  let(:transit_itinerary) { create(:transit_itinerary)}
  let(:transit_serializer) { Api::V1::ItinerarySerializer.new(transit_itinerary)}
  let(:transit_serialization) do
    JSON.parse(
      ActiveModelSerializers::Adapter.create(
        transit_serializer
      ).to_json
    )
  end

  let(:paratransit_itinerary) { create(:paratransit_itinerary)}
  let(:paratransit_serializer) { Api::V1::ItinerarySerializer.new(paratransit_itinerary)}
  let(:paratransit_serialization) do
    JSON.parse(
      ActiveModelSerializers::Adapter.create(
        paratransit_serializer
      ).to_json
    )
  end

  it 'faithfully serializes itineraries' do
    expect(transit_serialization['cost']).to eq(transit_itinerary.cost)
    # expect(transit_serialization['discounts']).to eq( ? )
    expect(transit_serialization['duration']).to eq(transit_itinerary.duration)
    expect(transit_serialization['end_location']).to eq({
      geometry: {
        location: {
          lat: transit_itinerary.trip.destination.lat.to_f,
          lng: transit_itinerary.trip.destination.lng.to_f
        }
      },
      address_components:[{"long_name"=>"100", "short_name"=>"100", "types"=>["street_number"]}, {"long_name"=>"Cambridgepark Drive", "short_name"=>"Cambridgepark Drive", "types"=>["route"]}, {"long_name"=>"Cambridge", "short_name"=>"Cambridge", "types"=>["locality", "political"]}, {"long_name"=>"02140", "short_name"=>"02140", "types"=>["postal_code"]}, {"long_name"=>"MA", "short_name"=>"MA", "types"=>["administrative_area_level_1", "political"]}, {"long_name"=>nil, "short_name"=>nil, "types"=>["administrative_area_level_2", "political"]}],
      formatted_address: "100 Cambridgepark Drive, Cambridge, MA 02140",
      id: transit_itinerary.id,
      name: "Old Cambridge Systematics",
      stop_code: nil
    }.with_indifferent_access)
    expect(transit_serialization['end_time']).to eq(transit_itinerary.end_time.iso8601)
    expect(transit_serialization['id']).to eq(transit_itinerary.id)
    expect(transit_serialization['json_legs']).to eq(transit_itinerary.legs)
    expect(transit_serialization['logo_url']).to eq(transit_itinerary.service.full_logo_url)
    expect(transit_serialization['phone']).to eq(transit_itinerary.service.formatted_phone)
    # expect(transit_serialization['prebooking_questions']).to eq( ? )
    # expect(transit_serialization['product_id']).to eq( ? )
    expect(transit_serialization['returned_mode_code']).to eq('mode_transit')
    # Check each schedule:
    paratransit_itinerary.service.schedules.each_with_index do |schedule, i|
      expect(paratransit_serialization['schedule'][i]).to eq(          {
        day: Date::DAYNAMES[schedule.day],
        start: [schedule_time_to_string(schedule.start_time)],
        end: [schedule_time_to_string(schedule.end_time)]
      }.with_indifferent_access)
    end
    expect(transit_serialization['segment_index']).to eq(0)
    # expect(transit_serialization['service_bookable']).to eq( ? )
    # Check each comment:
    paratransit_itinerary.service.descriptions.each do |loc, desc|
      expect(paratransit_serialization['service_comments'][loc.to_s]).to eq(desc)
    end
    expect(transit_serialization['service_id']).to eq(transit_itinerary.service.id)
    expect(transit_serialization['service_name']).to eq(transit_itinerary.service.name)
    expect(transit_serialization['start_location']).to eq({
      geometry: {
        location: {
          lat: transit_itinerary.trip.origin.lat,
          lng: transit_itinerary.trip.origin.lng
        }
      },
      address_components: [{"long_name"=>"101", "short_name"=>"101", "types"=>["street_number"]}, {"long_name"=>"Station Landing", "short_name"=>"Station Landing", "types"=>["route"]}, {"long_name"=>"Medford", "short_name"=>"Medford", "types"=>["locality", "political"]}, {"long_name"=>"02139", "short_name"=>"02139", "types"=>["postal_code"]}, {"long_name"=>"MA", "short_name"=>"MA", "types"=>["administrative_area_level_1", "political"]}, {"long_name"=>nil, "short_name"=>nil, "types"=>["administrative_area_level_2", "political"]}],
      formatted_address: "101 Station Landing, Medford, MA 02139",
      id: transit_itinerary.id,
      name: "Central Square",
      stop_code: nil
    }.with_indifferent_access)
    expect(transit_serialization['start_time']).to eq(transit_itinerary.start_time.iso8601)
    expect(transit_serialization['url']).to eq(transit_itinerary.service.url)
    # expect(transit_serialization['user_registered']).to eq( ? )
    expect(transit_serialization['walk_distance']).to eq(transit_itinerary.walk_distance)
    expect(transit_serialization['walk_time']).to eq(transit_itinerary.walk_time)
  end

end
