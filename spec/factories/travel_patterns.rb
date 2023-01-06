FactoryBot.define do
  factory :travel_pattern do
    sequence(:name) { |n| "Travel Pattern #{n}" }

    association :agency, factory: :transportation_agency
    booking_window { association :booking_window, agency: agency }
    origin_zone { association :origin_zone, agency: agency }
    destination_zone { association :destination_zone, agency: agency }

    with_trip_purpose
    with_empty_service_schedule
    with_funding_source

    trait :with_empty_service_schedule do
      before(:create) do |travel_pattern|
        service_schedule = create(:service_schedule, agency: travel_pattern.agency)
        travel_pattern.travel_pattern_service_schedules << build(:travel_pattern_service_schedule, service_schedule: service_schedule, travel_pattern: travel_pattern)
      end
    end

    trait :with_weekly_pattern_schedule do
      before(:create) do |travel_pattern|
        service_schedule = create(:weekly_pattern_schedule, agency: travel_pattern.agency)
        travel_pattern.travel_pattern_service_schedules << build(:travel_pattern_service_schedule, service_schedule: service_schedule, travel_pattern: travel_pattern)
      end
    end

    trait :with_calendar_date_schedule do
      before(:create) do |travel_pattern|
        service_schedule = create(:calendar_date_schedule, agency: travel_pattern.agency)
        travel_pattern.travel_pattern_service_schedules << build(:travel_pattern_service_schedule, service_schedule: service_schedule, travel_pattern: travel_pattern)
      end
    end

    trait :with_trip_purpose do
      before(:create) do |travel_pattern|
        new_purpose = create(:purpose, agency: travel_pattern.agency)
        travel_pattern.purposes << new_purpose
      end
    end

    trait :with_funding_source do
      before(:create) do |travel_pattern|
        funding_source = create(:funding_source, agency: travel_pattern.agency)
        travel_pattern.funding_sources << funding_source
      end
    end
  end
end
