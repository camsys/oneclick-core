FactoryGirl.define do
  factory :user_eligibility do

    eligibility

    trait :confirmed do
      value true
    end

    trait :denied do
      value false
    end
  end
end
