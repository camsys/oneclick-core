FactoryBot.define do
  factory :booking_window do
    association :agency, factory: :transportation_agency
    sequence(:name) { |n| "Booking Window #{n}" }
    minimum_days_notice { 1 }
    maximum_days_notice { 30 }
    minimum_notice_cutoff_hour { 12 }
  end
end
