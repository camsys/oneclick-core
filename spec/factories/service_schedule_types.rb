FactoryBot.define do
  factory :service_schedule_type do
    to_create do |instance|
      instance.id = ServiceScheduleType.find_or_create_by(name: instance.name).id
      instance.reload
    end

    name { "Weekly pattern" }

    factory :calendar_date_schedule_type do
      name { "Selected calendar dates" }
    end

    factory :weekly_pattern_schedule_type do
      name { "Weekly pattern" }
    end
  end
end