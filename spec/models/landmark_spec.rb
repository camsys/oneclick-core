require 'rails_helper'

RSpec.describe Landmark, type: :model do
  let(:landmark) { create :landmark }

  it "builds a google_place_hash with proper address components" do
    expect(landmark.google_place_hash[:address_components]).to eq([{:long_name=>"201", :short_name=>"201", :types=>["street_number"]}, {:long_name=>"Station Landing", :short_name=>"Station Landing", :types=>["route"]}, {:long_name=>"Medford", :short_name=>"Medford", :types=>["locality", "political"]}, {:long_name=>"MA", :short_name=>"MA", :types=>["postal_code"]}, {:long_name=>"02155", :short_name=>"02155", :types=>["administrative_area_level_1", "political"]}])
  end

  it "builds a google_place_hash with geometry" do
    expect(landmark.google_place_hash[:geometry]).to eq({:location=>{:lat=>"42.401697", :lng=>"71.081818"}})
  end

  it "builds a google_place_hash with a proper name" do
    expect(landmark.google_place_hash[:name]).to eq("Cambridge Systematics")
  end
end
