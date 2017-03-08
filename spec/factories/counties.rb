require './spec/helpers/r_geo_spec_helpers'
include RGeoSpecHelpers

FactoryGirl.define do
  factory :county do
    name "Fakecounty"
    state "MA"
    geom RGeoSpecHelper.new.multi_polygon
  end
end
