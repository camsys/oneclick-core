FactoryBot.define do
  factory :traveler_transit_agency do
    association :user
    association :transportation_agency, factory: :transportation_agency
  end
end