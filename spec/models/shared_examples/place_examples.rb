require 'rails_helper'

RSpec.shared_examples "place" do
  let(:factory) { described_class.to_s.underscore.to_sym }
  let(:place) { create(factory) }
  let(:place2) { create(factory, name: place.name + " 2") }
  let(:place3) { create(factory, name: "xyz") }
  let(:place_dup) { create(factory) }
  let(:google_place_attrs) { {"address_components":[{"long_name":"101","short_name":"101","types":["street_number"]},{"long_name":"Station Landing","short_name":"Station Landing","types":["route"]},{"long_name":"Medford","short_name":"Medford","types":["locality","political"]},{"long_name":"02155","short_name":"02155","types":["postal_code"]},{"long_name":"MA","short_name":"MA","types":["administrative_area_level_1","political"]}],
    "formatted_address":"101 Station Landing, Medford, MA 02155","geometry":{"location":{"lat":"42.401697","lng":"-71.081818"}},"id":2,"name":"Work"}
  }
  
  # Attributes
  it { should respond_to :name, :street_number, :route, :city, :state, :zip, :lat, :lng, :geom }
  
  # Methods
  it { should respond_to :to_point, 
                         :build_geometry, 
                         :update_from_google_place_attributes, 
                         :similar_to?,
                         :formatted_address,
                         :short_formatted_address }
  it "should respond to class methods" do
    expect(described_class).to respond_to(
      :get_by_query_str, 
      :unique, 
      :initialize_from_google_place_attributes
    )
  end
  
  it "automatically builds geometry on save" do
    new_place = build(factory)
    expect(new_place.geom).to be_nil
    
    new_place.save
    expect(new_place.geom).to be
    expect(new_place.geom.x).to eq(new_place.lng.to_f)
    expect(new_place.geom.y).to eq(new_place.lat.to_f)
  end
  
  it "builds a place from google place attributes" do
    new_place = described_class.initialize_from_google_place_attributes(google_place_attrs)
    new_place.save
    expect(new_place.lat.to_f).to eq(42.401697)
    expect(new_place.lng.to_f).to eq(-71.081818)
    expect(new_place.name).to eq("Work")
    expect(new_place.street_number).to eq("101")
    expect(new_place.route).to eq("Station Landing")
    expect(new_place.city).to eq("Medford")
    expect(new_place.state).to eq("MA")
    expect(new_place.zip).to eq("02155")
  end
  
  it "produces a formatted address" do
    expect(place.formatted_address).to eq("#{place.street_number} #{place.route}, #{place.city}, #{place.state} #{place.zip}")
  end
  
  it "produces a short formatted address" do
    expect(place.short_formatted_address).to eq("#{place.street_number} #{place.route}")
  end
  
  it "compares similar places by name, lat, and lng" do
    expect(place.similar_to?(place_dup)).to be true
    
    place_dup.lat = place_dup.lat + 0.0001
    expect(place.similar_to?(place_dup)).to be false
    
    place_dup.lat = place.lat
    expect(place.similar_to?(place_dup)).to be true

    place_dup.lng = place_dup.lng + 0.0001
    expect(place.similar_to?(place_dup)).to be false
    
    expect(place.similar_to?(place2)).to be false
  end
  
  it "filters out duplicate places by name, lat, lng" do
    places = [place, place2, place3, place_dup]
    
    expect(described_class.count).to eq(4)
    expect(described_class.unique.count).to eq(3)
  end
  
  it "searches across names by a query string, without duplicates" do
    places = [place, place2, place3, place_dup]
    
    expect(described_class.count).to eq(4)
    
    # Strict search
    expect(described_class.get_by_query_str(place.name).count).to eq(1)
    returned_place = described_class.get_by_query_str(place.name).first
    expect(returned_place.similar_to?(place)).to be true
    
    # Approx searches
    expect(described_class.get_by_query_str("%#{place.name.slice(0,3)}%").count).to eq(2)
    expect(described_class.get_by_query_str("%#{place.name}%").count).to eq(2)    
  end
  
  
end
