FactoryBot.define do
  factory :travel_pattern_service_schedule do
    sequence(:priority) { |n| n.to_i }

    association :travel_pattern
    association :service_schedule
  end
end
