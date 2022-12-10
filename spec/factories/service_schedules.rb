FactoryBot.define do
  factory :service_schedule do
    association :agency, factory: :transportation_agency
    association :service_schedule_type, factory: :weekly_pattern_schedule_type 
    
    sequence(:name) { |n| "Service Schedule #{n}"}
    # sequence(:priority)

    factory :weekly_pattern_schedule do
      after(:create) do |service_schedule|
        create(:weekly_pattern_sub_schedule, service_schedule: service_schedule)
      end
    end

    factory :calendar_date_schedule do
      association :service_schedule_type, factory: :calendar_date_schedule_type 
      after(:create) do |service_schedule|
        create(:calendar_date_sub_schedule, service_schedule: service_schedule)
      end
    end

    trait :with_travel_pattern do
      after(:create) do |service_schedule|
        travel_pattern = create(:travel_pattern, agency: service_schedule.agency)
        create(:travel_pattern_service_schedule, service_schedule: service_schedule, travel_pattern: travel_pattern)
      end
    end
  end
end
