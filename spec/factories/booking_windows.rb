FactoryBot.define do
  factory :booking_window do
    agency nil
    name "MyString"
    description "MyString"
    minimum_days_notice 1
    maximun_days_notice 1
    notice_cutoff_time "2022-06-06 19:28:21"
  end
end
