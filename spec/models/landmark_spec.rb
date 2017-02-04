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

  it "successfully updates the landmarks" do
    result, message = Landmark.update 'spec/files/good_landmarks.csv'

    expect(result).to eq(true)
    expect(Landmark.count).to eq(3)
  end

  it "handles a malformed landmarks file" do
    
    #First load the good landmarks
    Landmark.update 'spec/files/good_landmarks.csv'
    
    #Try to load bad landmarks
    result, message = Landmark.update 'spec/files/bad_landmarks.csv'

    #Confirm that the bad landmarks file was detected
    expect(result).to eq(false)
    expect(message).to eq("Error Reading File")

    #The number of good landmarks should be unchanged
    expect(Landmark.count).to eq(3)
  end
end
