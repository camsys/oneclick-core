FactoryBot.define do
  factory :user_eligibility do

    eligibility

    trait :confirmed do
      value { true }
    end

    trait :denied do
      value { false }
    end

    factory :answered_veteran do 
      association :eligibility, factory: :veteran
    end 

  end
end
