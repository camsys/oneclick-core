require './spec/helpers/r_geo_spec_helpers'
include RGeoSpecHelpers

FactoryGirl.define do
  factory :zipcode, class: 'Zipcode' do
    name "00000"
    geom RGeoSpecHelper.new.multi_polygon([1,1])
    initialize_with { Zipcode.find_or_create_by(name: name)}
  end

  factory :county, class: 'County' do
    name "Fakecounty"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon([0,0])
    initialize_with { County.find_or_create_by(name: name, state: state)}
  end

  factory :city, class: 'City' do
    name "Notrealburg"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon([-1,-1])
    initialize_with { City.find_or_create_by(name: name, state: state)}
  end

  factory :county_2, class: 'County' do
    name "Fakecounty 2"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon([-1,1])
    initialize_with { County.find_or_create_by(name: name, state: state)}
  end

  factory :county_3, class: 'County' do
    name "Fakecounty 3"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon([1,-1])
    initialize_with { County.find_or_create_by(name: name, state: state)}
  end

  factory :custom_geography, class: 'CustomGeography' do
    name "Custom Geo"
    geom RGeoSpecHelper.new.multi_polygon([0,-1])
    initialize_with { CustomGeography.find_or_create_by(name: name)}
  end
end
