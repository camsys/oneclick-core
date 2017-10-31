require 'rails_helper'

RSpec.describe Api::V2::WaypointSerializer, type: :serializer do
  
  let(:waypoint) { create(:waypoint) }
  let(:serialization) { Api::V2::WaypointSerializer.new(waypoint).to_h }
  
  let(:attributes) {
    [ 
      :name, 
      :street_number, 
      :route, 
      :city, 
      :state, 
      :zip, 
      :lat, 
      :lng, 
      :formatted_address
    ]
  }
  
  it "faithfully serializes a waypoint" do
    attributes.each do |attr|
      expect(serialization[attr]).to eq(waypoint.send(attr))
    end
  end

end
