require 'rails_helper'

RSpec.describe MapService do
  
  # Stubbed OTP Responses
  let!(:trip) { create(:trip)}
  let!(:itin) { create(:paratransit_itinerary, trip: trip) }

it 'creates a map url' do
  ms = MapService.new(itin)
  # This is a map url with an origin an destination but no legs
  expect(ms.create_static_map).to eq("https://maps.googleapis.com/maps/api/staticmap?maptype=roadmap&size=700x435&markers=icon:http://maps.google.com/mapfiles/dd-start.png%7C42.365047,-71.103359&markers=icon:http://maps.google.com/mapfiles/dd-end.png%7C42.39467,-71.144785")
end
  
  
end
