FactoryBot.define do
  factory :travel_pattern_purpose do
    association :travel_pattern
    association :purpose
  end
end
