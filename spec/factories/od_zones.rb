FactoryBot.define do

  factory :od_zone, aliases: [:origin_zone, :destination_zone] do
    sequence(:name) { |n| "OD Zone #{n}" }
    association :agency, factory: :transportation_agency
    association :region
  end

end