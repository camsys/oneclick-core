require './spec/helpers/r_geo_spec_helpers'
include RGeoSpecHelpers

FactoryGirl.define do
  factory :zipcode, class: 'Zipcode' do
    name "00000"
    geom RGeoSpecHelper.new.multi_polygon([0,0])
    initialize_with { Zipcode.find_or_create_by(name: name)}
  end
end

FactoryGirl.define do
  factory :county, class: 'County' do
    name "Fakecounty"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon([1,1])
    initialize_with { County.find_or_create_by(name: name, state: state)}
  end
end

FactoryGirl.define do
  factory :city, class: 'City' do
    name "Notrealburg"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon([-1,-1])
    initialize_with { City.find_or_create_by(name: name, state: state)}
  end
end
