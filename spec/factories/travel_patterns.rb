FactoryBot.define do
  factory :travel_pattern do
    sequence(:name) { |n| "Travel Pattern #{n}" }

    association :agency, factory: :transportation_agency
    booking_window { association :booking_window, agency: agency }
    origin_zone { association :origin_zone, agency: agency }
    destination_zone { association :destination_zone, agency: agency }

    # For overriding the default traits a travel pattern is created with
    transient do 
      has_service_schedule { false }
      has_trip_purpose { false }
      has_funding_source { false }
    end

    # A Travel Pattern requires at least one Service Schedule, Trip Purpose, and Funding Source
    with_empty_service_schedule
    with_trip_purpose
    with_funding_source

    # Service Schedule Traits
    trait :with_empty_service_schedule do
      before(:create) do |travel_pattern, evaluator|
        unless evaluator.has_service_schedule
          service_schedule = create(:service_schedule, agency: travel_pattern.agency)
          tpss = build(:travel_pattern_service_schedule, travel_pattern: travel_pattern, service_schedule: service_schedule)
          travel_pattern.travel_pattern_service_schedules << tpss
        end
      end
    end

    trait :with_weekly_pattern_schedule do
      transient do 
        has_service_schedule { true }
      end

      before(:create) do |travel_pattern|
        service_schedule = create(:weekly_pattern_schedule, agency: travel_pattern.agency)
        tpss = build(:travel_pattern_service_schedule, travel_pattern: travel_pattern, service_schedule: service_schedule)
        travel_pattern.travel_pattern_service_schedules << tpss
      end
    end

    trait :with_calendar_date_schedule do
      transient do 
        has_service_schedule { true }
      end

      before(:create) do |travel_pattern|
        service_schedule = create(:calendar_date_schedule, agency: travel_pattern.agency)
        tpss = build(:travel_pattern_service_schedule, travel_pattern: travel_pattern, service_schedule: service_schedule)
        travel_pattern.travel_pattern_service_schedules << tpss
      end
    end

    # Trip Purpose Traits
    trait :with_trip_purpose do
      before(:create) do |travel_pattern, evaluator|
        travel_pattern.purposes << create(:purpose, agency: travel_pattern.agency) unless evaluator.has_trip_purpose
      end
    end

    # Funding Source Traits
    trait :with_funding_source do 
      before(:create) do |travel_pattern, evaluator|
        travel_pattern.funding_sources << create(:funding_source, agency: travel_pattern.agency) unless evaluator.has_funding_source
      end
    end
  end
end
