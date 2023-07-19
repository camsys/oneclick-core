FactoryBot.define do
  factory :schedule do
    service { nil }
    day { 1 }
    start_time { 28800 }  # 8:00am
    end_time { 72000 }    # 8:00pm

    factory :all_day_schedule do
      start_time { 0 }    # 12:00am
      end_time { 86400 }  # 12:00am next day
    end

    factory :micro_schedule do
      start_time { 1 }    # 12:01am
      end_time { 2 }      # 12:02am
    end

    factory :midnight_schedule do
      start_time { 82800 }
      end_time { 86400 }
    end
  end
end
