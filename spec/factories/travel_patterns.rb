FactoryBot.define do
  factory :travel_pattern do
    sequence(:name) { |n| "Travel Pattern #{n}" }

    association :agency, factory: :transportation_agency
    booking_window { association :booking_window, agency: agency }
    origin_zone { association :origin_zone, agency: agency }
    destination_zone { association :destination_zone, agency: agency }

    before(:create) do |travel_pattern|
      funding_source = create(:funding_source)
      travel_pattern.travel_pattern_funding_sources << build(:travel_pattern_funding_source, funding_source: funding_source, travel_pattern: travel_pattern) 
      
      purpose = create(:purpose, agency: travel_pattern.agency)
      travel_pattern.travel_pattern_purposes << build(:travel_pattern_purpose, purpose: purpose, travel_pattern: travel_pattern)        
    end

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
    
  end
end
