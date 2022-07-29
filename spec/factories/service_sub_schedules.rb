FactoryBot.define do
  factory :service_sub_schedule do
    association :service_schedule
    day (Date.current + 2.days).wday
    start_time 9.hours
    end_time 17.hours

    factory :weekly_pattern_sub_schedule do
    end

    factory :calendar_date_sub_schedule do
      association :service_schedule, factory: :calendar_date_schedule
      day nil
      calendar_date Date.current + 3.days
    end
  end
end